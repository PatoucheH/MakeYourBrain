import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Interface pour typer les données
interface QuestionData {
  question_en: string;
  question_fr: string;
  explanation_en: string;
  explanation_fr: string;
  difficulty: string;
  answers_en: { text: string; is_correct: boolean }[];
  answers_fr: { text: string; is_correct: boolean }[];
}

serve(async (req) => {
  try {
    // 1. Créer le client Supabase avec les credentials admin
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // 2. Récupérer tous les thèmes
    const { data: themes, error: themesError } = await supabaseAdmin
      .from("themes")
      .select("id, icon");

    if (themesError) throw themesError;

    console.log(`Found ${themes.length} themes`);

    let totalQuestionsGenerated = 0;

    // 3. Pour chaque thème, générer des questions
    // 3. Pour chaque thème, générer des questions
    for (const theme of themes) {
      console.log(`Generating questions for theme: ${theme.icon}`);

      const { data: themeTranslation } = await supabaseAdmin
        .from("theme_translations")
        .select("name")
        .eq("theme_id", theme.id)
        .eq("language_code", "en")
        .single();

      const themeName = themeTranslation?.name || "General Knowledge";

      const TARGET_QUESTIONS = 5; // Nombre de nouvelles questions voulues
      let questionsAdded = 0;
      let attempts = 0;
      const MAX_ATTEMPTS = 3;

      // Boucle jusqu'à avoir 5 nouvelles questions (max 3 essais)
      while (questionsAdded < TARGET_QUESTIONS && attempts < MAX_ATTEMPTS) {
        attempts++;
        const questionsToGenerate = TARGET_QUESTIONS - questionsAdded;

        console.log(
          `Attempt ${attempts}: Generating ${questionsToGenerate} questions for ${themeName}`,
        );

        // 4. Appeler l'API Anthropic
        const anthropicResponse = await fetch(
          "https://api.anthropic.com/v1/messages",
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "x-api-key": Deno.env.get("ANTHROPIC_API_KEY") ?? "",
              "anthropic-version": "2023-06-01",
            },
            body: JSON.stringify({
              model: "claude-haiku-4-20250514",
              max_tokens: 4000,
              messages: [
                {
                  role: "user",
                  content: `Generate ${questionsToGenerate} multiple-choice quiz questions about ${themeName}.

CRITICAL: Respond ONLY with valid JSON, no markdown, no explanation, no preamble.

Format:
{
  "questions": [
    {
      "question_en": "English question text",
      "question_fr": "Texte de la question en français",
      "explanation_en": "English explanation",
      "explanation_fr": "Explication en français",
      "difficulty": "easy|medium|hard",
      "answers_en": [
        {"text": "Answer 1", "is_correct": false},
        {"text": "Answer 2", "is_correct": true},
        {"text": "Answer 3", "is_correct": false},
        {"text": "Answer 4", "is_correct": false}
      ],
      "answers_fr": [
        {"text": "Réponse 1", "is_correct": false},
        {"text": "Réponse 2", "is_correct": true},
        {"text": "Réponse 3", "is_correct": false},
        {"text": "Réponse 4", "is_correct": false}
      ]
    }
  ]
}

Requirements:
- Exactly 4 answers per question
- Only ONE correct answer (is_correct: true)
- Same difficulty for both languages
- Answers in same order (correct answer at same index)
- Mix of easy, medium, hard difficulties
- Generate UNIQUE questions, avoid common/obvious questions`,
                },
              ],
            }),
          },
        );

        if (!anthropicResponse.ok) {
          console.error(`Anthropic API error: ${anthropicResponse.statusText}`);
          continue;
        }

        const anthropicData = await anthropicResponse.json();
        const content = anthropicData.content[0].text;

        let cleanedContent = content.trim();
        if (cleanedContent.startsWith("```")) {
          cleanedContent = cleanedContent
            .replace(/```json\n?/g, "")
            .replace(/```\n?/g, "");
        }

        const generated = JSON.parse(cleanedContent);

        // 5. Tenter d'insérer les questions
        for (const q of generated.questions) {
          try {
            // Vérifier si la question existe déjà
            const { data: existingQuestion } = await supabaseAdmin
              .from("question_translations")
              .select("id")
              .eq("question_text", q.question_en)
              .eq("language_code", "en")
              .maybeSingle();

            if (existingQuestion) {
              console.log(
                `Question already exists: "${q.question_en.substring(0, 50)}..."`,
              );
              continue; // Passer à la question suivante
            }

            // Insérer la question (métadonnées)
            const { data: question, error: questionError } = await supabaseAdmin
              .from("questions")
              .insert({
                theme_id: theme.id,
                difficulty: q.difficulty,
                times_used: 0,
              })
              .select()
              .single();

            if (questionError) {
              console.error("Error inserting question:", questionError);
              continue;
            }

            // Insérer les traductions de la question (EN + FR)
            await supabaseAdmin.from("question_translations").insert([
              {
                question_id: question.id,
                language_code: "en",
                question_text: q.question_en,
                explanation: q.explanation_en,
              },
              {
                question_id: question.id,
                language_code: "fr",
                question_text: q.question_fr,
                explanation: q.explanation_fr,
              },
            ]);

            // Insérer les réponses
            for (let i = 0; i < q.answers_en.length; i++) {
              const { data: answer, error: answerError } = await supabaseAdmin
                .from("answers")
                .insert({
                  question_id: question.id,
                  is_correct: q.answers_en[i].is_correct,
                  display_order: i,
                })
                .select()
                .single();

              if (answerError) {
                console.error("Error inserting answer:", answerError);
                continue;
              }

              await supabaseAdmin.from("answer_translations").insert([
                {
                  answer_id: answer.id,
                  language_code: "en",
                  answer_text: q.answers_en[i].text,
                },
                {
                  answer_id: answer.id,
                  language_code: "fr",
                  answer_text: q.answers_fr[i].text,
                },
              ]);
            }

            questionsAdded++;
            totalQuestionsGenerated++;
            console.log(
              `✓ Added question ${questionsAdded}/${TARGET_QUESTIONS}`,
            );
          } catch (error) {
            console.error("Error processing question:", error);
          }
        }
      }

      console.log(
        `Finished ${themeName}: ${questionsAdded}/${TARGET_QUESTIONS} new questions added`,
      );
    }

    // 7. Retourner le résultat
    return new Response(
      JSON.stringify({
        success: true,
        message: `Successfully generated ${totalQuestionsGenerated} questions`,
        themes_processed: themes.length,
      }),
      {
        headers: { "Content-Type": "application/json" },
        status: 200,
      },
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        headers: { "Content-Type": "application/json" },
        status: 500,
      },
    );
  }
});
