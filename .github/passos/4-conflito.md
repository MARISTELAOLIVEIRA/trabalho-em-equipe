## ⚔️ Passo 4 de 5: resolva o conflito

Enquanto você trabalhava, eu (sua colega de equipe 😈) coloquei na `main` uma mudança **na mesma parte** do **EQUIPE.md**. O Git não sabe qual das duas versões manter, e isso é um **conflito**. Acontece o tempo todo em equipe, e resolver é tranquilo:

1. Abra o seu [PR #{{pr}}](https://github.com/{{usuario}}/{{repo}}/pull/{{pr}}). Lá embaixo aparece *This branch has conflicts that must be resolved*
2. Clique em **Resolve conflicts**
3. Você vai ver as marcas do Git:
   ```text
   <<<<<<< minha-parte
   - Seu Nome · Seu Curso
   =======
   - Robô do curso · revisor automático 🤖
   >>>>>>> main
   ```
   A sua versão fica em cima e a da `main` embaixo. Aqui as **duas** linhas devem ficar: **apague só as três linhas de marcas** (`<<<<<<<`, `=======` e `>>>>>>>`)
4. Clique em **Mark as resolved** e depois em **Commit merge**

⏳ Fico de olho!
