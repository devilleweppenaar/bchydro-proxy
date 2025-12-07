import js from "@eslint/js";

export default [
  {
    ignores: ["node_modules/", "dist/", ".wrangler/"],
  },
  {
    files: ["src/**/*.js", "tests/**/*.js"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module",
      globals: {
        console: "readonly",
        process: "readonly",
        Request: "readonly",
        Response: "readonly",
        fetch: "readonly",
        caches: "readonly",
        URL: "readonly",
      },
    },
    rules: {
      ...js.configs.recommended.rules,
      "no-unused-vars": ["warn", { argsIgnorePattern: "^_" }],
      "no-undef": "error",
      "no-console": "warn",
      "prefer-const": "warn",
      "no-var": "error",
      semi: ["error", "always"],
      quotes: ["error", "double"],
      indent: ["warn", 2],
      eqeqeq: ["error", "always"],
    },
  },
];
