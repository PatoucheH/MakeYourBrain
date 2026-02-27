import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ========================================
// 🎯 CONFIGURATION - Modifiez ici
// ========================================
const QUESTIONS_PER_CONCEPT = 15       // Questions par concept par jour
const MAX_CONCEPTS_TO_AVOID = 100      // Concepts à éviter dans le prompt
// ========================================

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // ===== RÉCUPÉRER LES PARAMÈTRES (concept et theme_id optionnels) =====
    const body = await req.json().catch(() => ({}))
    const forcedConcept = body.concept ?? null
    const forcedConceptFr = body.concept_fr ?? null
    const forcedThemeId = body.theme_id ?? null

    if (forcedConcept) {
      console.log(`🎯 Mode manuel: Concept forcé = "${forcedConcept}"`)
    }

    // ===== RÉCUPÉRER TOUS LES THÈMES =====
    let themesQuery = supabaseAdmin
      .from('themes')
      .select('id, icon')
      .order('id', { ascending: true })

    // Si theme_id fourni, utiliser ce thème spécifique
    if (forcedThemeId) {
      themesQuery = themesQuery.eq('id', forcedThemeId)
    }

    const { data: allThemes, error: themesError } = await themesQuery

    if (themesError) throw themesError

    if (!allThemes || allThemes.length === 0) {
      throw new Error('No themes found')
    }

    let theme

    if (forcedThemeId) {
      // Mode manuel: utiliser le thème spécifié
      theme = allThemes[0]
      console.log(`🎯 Mode manuel: Thème forcé`)
    } else {
      // Mode automatique: rotation équitable
      console.log(`📊 ${allThemes.length} thèmes disponibles`)

      const themeCounts = await Promise.all(
        allThemes.map(async (t) => {
          const { count } = await supabaseAdmin
            .from('questions')
            .select('id', { count: 'exact', head: true })
            .eq('theme_id', t.id)

          return { theme_id: t.id, icon: t.icon, concept_count: count || 0 }
        })
      )

      themeCounts.sort((a, b) => a.concept_count - b.concept_count)
      const selectedThemeData = themeCounts[0]
      theme = allThemes.find(t => t.id === selectedThemeData.theme_id)

      console.log(`\n🎯 Thème sélectionné (${selectedThemeData.concept_count} concepts existants)`)
    }

    console.log(`🎨 THEME: ${theme.icon}`)

    const { data: themeTranslation } = await supabaseAdmin
      .from('theme_translations')
      .select('name')
      .eq('theme_id', theme.id)
      .eq('language_code', 'en')
      .single()

    const themeName = themeTranslation?.name || 'General'
    console.log(`📝 ${themeName}`)

    // ===== RÉCUPÉRER LES CONCEPTS DÉJÀ COUVERTS POUR CE THÈME =====
    const { data: usedConcepts } = await supabaseAdmin
      .from('question_concepts')
      .select('concept')
      .eq('theme_id', theme.id)
      .order('created_at', { ascending: false })

    const conceptsList = usedConcepts?.map(c => c.concept) || []
    console.log(`📚 ${conceptsList.length} concepts déjà couverts pour ce thème`)

    // ===== CHOISIR LE CONCEPT =====
    let conceptName, chosenConcept

    if (forcedConcept) {
      // ===== MODE MANUEL : UTILISER LE CONCEPT FOURNI =====
      conceptName = forcedConcept
      chosenConcept = {
        concept: forcedConcept,
        concept_fr: forcedConceptFr || forcedConcept
      }
      console.log(`💡 Concept forcé: "${conceptName}"`)

      // Vérifier qu'il n'existe pas déjà
      const conceptExists = conceptsList.some(existing => 
        existing.toLowerCase().includes(conceptName.toLowerCase()) ||
        conceptName.toLowerCase().includes(existing.toLowerCase())
      )

      if (conceptExists) {
        console.log(`⚠️ Ce concept existe déjà pour ce thème !`)
        return new Response(
          JSON.stringify({
            success: false,
            message: 'Concept already exists for this theme',
            theme: themeName,
            concept: conceptName,
            existing_concepts: conceptsList
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
        )
      }
    } else {
      // ===== MODE AUTOMATIQUE : DEMANDER À CLAUDE DE CHOISIR =====
      console.log(`🔍 Recherche d'un nouveau concept...`)

      const conceptPrompt = `You are helping create quiz questions for a "${themeName}" themed quiz app for a GENERAL AUDIENCE.

${conceptsList.length > 0 ? `
🚫 CRITICAL - These concepts have ALREADY been covered:
${conceptsList.slice(0, MAX_CONCEPTS_TO_AVOID).map((c, i) => `${i + 1}. ${c}`).join('\n')}

You MUST choose a COMPLETELY DIFFERENT concept not in this list.
` : ''}

Task: Suggest ONE specific, interesting concept related to "${themeName}".

Requirements:
- Must be BROAD and WELL-KNOWN (not too specific)
- Should be a general topic that allows multiple angles
- Must be recognizable by most people
- Must be related to ${themeName}
- Should allow for diverse question angles at different difficulty levels
- Must be COMPLETELY DIFFERENT from all concepts listed above

Examples of GOOD concepts (BROAD): 
  - "The Legend of Zelda" (not "The Legend of Zelda: Ocarina of Time")
  - "World War II" (not "The Battle of Stalingrad")
  - "The Solar System" (not "Jupiter's Great Red Spot")
  - "Vincent van Gogh" (not "Vincent van Gogh's Starry Night")
  
Examples of BAD concepts (too narrow/specific):
  - "The Legend of Zelda: Ocarina of Time Water Temple"
  - "The Third Punic War's naval tactics"
  - "Cytochrome P450 enzyme family"
  
Examples of BAD concepts (too basic):
  - "Colors", "Numbers", "Animals"

Respond ONLY with valid JSON (no markdown):

{
  "concept": "Specific concept name in English",
  "concept_fr": "Nom du concept en français"
}`

      const conceptResponse = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': Deno.env.get('ANTHROPIC_API_KEY') ?? '',
          'anthropic-version': '2023-06-01'
        },
        body: JSON.stringify({
          model: 'claude-sonnet-4-20250514',
          max_tokens: 500,
          messages: [{ role: 'user', content: conceptPrompt }]
        })
      })

      if (!conceptResponse.ok) {
        const errorText = await conceptResponse.text()
        console.error(`❌ Erreur API concept: ${conceptResponse.status}`, errorText)
        throw new Error(`Concept API error: ${conceptResponse.status}`)
      }

      const conceptData = await conceptResponse.json()
      let conceptContent = conceptData?.content?.[0]?.text?.trim() || ''

      if (conceptContent.startsWith('```')) {
        conceptContent = conceptContent.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim()
      }

      try {
        chosenConcept = JSON.parse(conceptContent)
      } catch (e) {
        console.error('❌ Erreur parsing JSON concept:', e)
        throw new Error('Failed to parse concept JSON')
      }

      conceptName = chosenConcept.concept
      console.log(`💡 Concept choisi automatiquement: "${conceptName}"`)

      // Vérifier que le concept n'existe pas déjà
      const conceptExists = conceptsList.some(existing => 
        existing.toLowerCase().includes(conceptName.toLowerCase()) ||
        conceptName.toLowerCase().includes(existing.toLowerCase())
      )

      if (conceptExists) {
        console.log(`⚠️ Concept déjà existant, abandon pour aujourd'hui`)
        return new Response(
          JSON.stringify({
            success: false,
            message: 'Concept already exists, will retry tomorrow',
            theme: themeName,
            attempted_concept: conceptName
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // ===== ÉTAPE 2 : GÉNÉRER LES QUESTIONS SUR CE CONCEPT =====
    console.log(`📝 Génération de ${QUESTIONS_PER_CONCEPT} questions sur "${conceptName}"...`)

    // Calculer la répartition des difficultés
    const easyCount = 6
    const hardCount = 3
    const mediumCount = QUESTIONS_PER_CONCEPT - easyCount - hardCount

    const questionsPrompt = `Generate ${QUESTIONS_PER_CONCEPT} diverse and high-quality quiz questions about "${conceptName}" (theme: ${themeName}).

CRITICAL REQUIREMENTS:
- ALL questions MUST be specifically about "${conceptName}"
- Questions must be DIVERSE (different aspects, angles, perspectives)
- Difficulty distribution: ${easyCount} EASY, ${mediumCount} MEDIUM, ${hardCount} HARD
- Factually accurate and verifiable
- 4 answers per question (exactly 1 correct)
- Interesting and educational
- Questions should range from basic facts to deeper analysis

Difficulty guidelines:
- EASY: Requires genuine knowledge of the concept, not just common sense. The answer should not be guessable by someone unfamiliar with "${conceptName}". Ask about well-known but specific facts. (${easyCount} questions)
  ✅ Good example: "What is the main weapon used by Link in The Legend of Zelda?" (specific but known by fans)
  ❌ Bad example: "What color is the sky?" or "Who is the main character of Zelda?" (too trivial)
- MEDIUM: Standard knowledge, requires familiarity with the topic. About 40-50% of people interested in the theme should know this. (${mediumCount} questions)
  Example: "What year did World War II end?" or "What is the process by which plants make food?"
- HARD: Specific details, deeper knowledge, less commonly known facts. Only enthusiasts or experts should know this. (${hardCount} questions)
  Example: "Which treaty ended World War I?" or "What is the smallest bone in the human body?"

BALANCE: 
- EASY should require real knowledge of "${conceptName}", not just common sense. Someone who knows nothing about this topic should NOT be able to guess easily.
- MEDIUM should be known by about 40-50% of people with some interest in the topic.
- HARD should be known by about 15-25% (enthusiasts and experts only).
- NEVER generate trivially obvious questions like "What is X famous for?" or "Who is the creator of Y?"

RESPOND ONLY WITH VALID JSON (no markdown, no explanation):

{
  "questions": [
    {
      "question_en": "Question in English",
      "question_fr": "Question en français",
      "explanation_en": "Detailed explanation why this is correct (2-3 sentences)",
      "explanation_fr": "Explication détaillée en français (2-3 phrases)",
      "difficulty": "easy",
      "answers_en": [
        {"text": "Wrong answer 1", "is_correct": false},
        {"text": "Correct answer", "is_correct": true},
        {"text": "Wrong answer 2", "is_correct": false},
        {"text": "Wrong answer 3", "is_correct": false}
      ],
      "answers_fr": [
        {"text": "Mauvaise réponse 1", "is_correct": false},
        {"text": "Bonne réponse", "is_correct": true},
        {"text": "Mauvaise réponse 2", "is_correct": false},
        {"text": "Mauvaise réponse 3", "is_correct": false}
      ]
    }
  ]
}`

    const questionsResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': Deno.env.get('ANTHROPIC_API_KEY') ?? '',
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 16000,
        messages: [{ role: 'user', content: questionsPrompt }]
      })
    })

    if (!questionsResponse.ok) {
      const errorText = await questionsResponse.text()
      console.error(`❌ Erreur API questions: ${questionsResponse.status}`, errorText)
      throw new Error(`Questions API error: ${questionsResponse.status}`)
    }

    const questionsData = await questionsResponse.json()
    let questionsContent = questionsData?.content?.[0]?.text?.trim() || ''

    if (questionsContent.startsWith('```')) {
      questionsContent = questionsContent.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim()
    }

    let generated
    try {
      generated = JSON.parse(questionsContent)
    } catch (e) {
      console.error('❌ Erreur parsing JSON questions:', e)
      console.log('Raw content:', questionsContent.substring(0, 500))
      throw new Error('Failed to parse questions JSON')
    }

    if (!generated?.questions || !Array.isArray(generated.questions)) {
      console.error('❌ Format invalide: pas de tableau questions')
      throw new Error('Invalid questions format')
    }

    // ===== ÉTAPE 3 : ENREGISTRER LE CONCEPT EN PREMIER =====
    const { data: insertedConcept, error: conceptErr } = await supabaseAdmin
      .from('question_concepts')
      .insert({
        concept: conceptName,
        concept_en: chosenConcept.concept,
        concept_fr: chosenConcept.concept_fr || conceptName,
        theme_id: theme.id
      })
      .select()
      .single()

    if (conceptErr || !insertedConcept) {
      throw new Error(`Erreur insertion concept: ${conceptErr?.message}`)
    }

    const conceptId = insertedConcept.id
    console.log(`💾 Concept enregistré: "${conceptName}" (id: ${conceptId})`)

    // ===== ÉTAPE 4 : INSÉRER TOUTES LES QUESTIONS =====
    let added = 0
    const difficultyCount = { easy: 0, medium: 0, hard: 0 }

    for (const q of generated.questions) {
      try {
        // Validations
        if (!q.question_en || !q.question_fr || 
            !Array.isArray(q.answers_en) || q.answers_en.length !== 4 ||
            !Array.isArray(q.answers_fr) || q.answers_fr.length !== 4) {
          console.log('⚠️ Question incomplète')
          continue
        }

        const correctEn = q.answers_en.filter(a => a.is_correct).length
        const correctFr = q.answers_fr.filter(a => a.is_correct).length
        if (correctEn !== 1 || correctFr !== 1) {
          console.log('⚠️ Pas exactement 1 bonne réponse')
          continue
        }

        // Vérifier que toutes les réponses ont du texte
        const allAnswersValid = q.answers_en.every(a => a.text && a.text.trim().length > 0) &&
                               q.answers_fr.every(a => a.text && a.text.trim().length > 0)
        if (!allAnswersValid) {
          console.log('⚠️ Réponses vides')
          continue
        }

        // Vérifier doublon exact
        const { data: dup } = await supabaseAdmin
          .from('question_translations')
          .select('id')
          .eq('question_text', q.question_en)
          .eq('language_code', 'en')
          .maybeSingle()

        if (dup) {
          console.log('⚠️ Doublon détecté')
          continue
        }

        // Normaliser la difficulté
        const difficulty = ['easy', 'medium', 'hard'].includes(q.difficulty) 
          ? q.difficulty 
          : 'medium'

        // Insérer question
        const { data: question, error: qErr } = await supabaseAdmin
          .from('questions')
          .insert({
            theme_id: theme.id,
            concept_id: conceptId,
            difficulty: difficulty,
            times_used: 0
          })
          .select()
          .single()

        if (qErr || !question) {
          console.error('❌ Erreur insertion question:', qErr?.message)
          continue
        }

        // Traductions question
        const { error: transErr } = await supabaseAdmin
          .from('question_translations')
          .insert([
            {
              question_id: question.id,
              language_code: 'en',
              question_text: q.question_en,
              explanation: q.explanation_en || ''
            },
            {
              question_id: question.id,
              language_code: 'fr',
              question_text: q.question_fr,
              explanation: q.explanation_fr || ''
            }
          ])

        if (transErr) {
          console.error('❌ Erreur traductions:', transErr.message)
          await supabaseAdmin.from('questions').delete().eq('id', question.id)
          continue
        }

        // Réponses
        const answersData = q.answers_en.map((a, i) => ({
          question_id: question.id,
          is_correct: a.is_correct,
          display_order: i
        }))

        const { data: insertedAnswers, error: answersErr } = await supabaseAdmin
          .from('answers')
          .insert(answersData)
          .select()

        if (answersErr || !insertedAnswers || insertedAnswers.length !== 4) {
          console.error('❌ Erreur réponses:', answersErr?.message)
          await supabaseAdmin.from('question_translations').delete().eq('question_id', question.id)
          await supabaseAdmin.from('questions').delete().eq('id', question.id)
          continue
        }

        // Traductions réponses
        const answerTrans = insertedAnswers.flatMap((ans, i) => [
          {
            answer_id: ans.id,
            language_code: 'en',
            answer_text: q.answers_en[i].text
          },
          {
            answer_id: ans.id,
            language_code: 'fr',
            answer_text: q.answers_fr[i].text
          }
        ])

        const { error: ansTransErr } = await supabaseAdmin
          .from('answer_translations')
          .insert(answerTrans)

        if (ansTransErr) {
          console.error('❌ Erreur traductions réponses:', ansTransErr.message)
          await supabaseAdmin.from('answers').delete().eq('question_id', question.id)
          await supabaseAdmin.from('question_translations').delete().eq('question_id', question.id)
          await supabaseAdmin.from('questions').delete().eq('id', question.id)
          continue
        }

        added++
        difficultyCount[difficulty]++

        console.log(`✅ [${added}/${QUESTIONS_PER_CONCEPT}] [${difficulty.toUpperCase()}] "${q.question_en.substring(0, 50)}..."`)

      } catch (e) {
        console.error('❌ Erreur traitement question:', e)
      }
    }

    // Si aucune question valide, supprimer le concept orphelin
    if (added === 0) {
      await supabaseAdmin.from('question_concepts').delete().eq('id', conceptId)
      throw new Error('Aucune question valide générée, concept supprimé')
    }

    console.log(`\n✅ ${themeName}: ${added} questions créées sur "${conceptName}"`)
    console.log(`📊 Répartition: ${difficultyCount.easy} easy, ${difficultyCount.medium} medium, ${difficultyCount.hard} hard`)
    console.log(`🎉 Terminé !`)

    return new Response(
      JSON.stringify({
        success: true,
        mode: forcedConcept ? 'manual' : 'automatic',
        theme: themeName,
        theme_icon: theme.icon,
        concept: conceptName,
        questions_generated: added,
        difficulty_distribution: difficultyCount,
        total_concepts_for_theme: conceptsList.length + 1
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('💥 Erreur fatale:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})