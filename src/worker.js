import { handle } from "../build/dev/javascript/bchydro_proxy/bchydro_proxy.mjs";

export default {
  fetch(request, env, _ctx) {
    return handle(request, env);
  },
};
