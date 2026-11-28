import { readFileSync } from 'node:fs';
import { registerHooks, stripTypeScriptTypes } from 'node:module';

const worker = new URL('../../entry/src/main/ets/platform/SessionSnapshotWorker.ets', import.meta.url).href;

// Exercise the production worker entry point, including its structured-clone and asynchronous boundary.
export const taskpool = {
  Task: class {
    constructor(fn, ...args) {
      this.args = structuredClone(args);
      this.fn = fn;
    }
  },
  async execute(task) {
    await new Promise(resolve => setImmediate(resolve));
    return task.fn(...task.args);
  }
};

export function registerSnapshotTaskpool() {
  registerHooks({
    resolve(specifier, context, next) {
      if (specifier === '../platform/SessionSnapshotWorker') return { url: worker, shortCircuit: true };
      if (context.parentURL === worker && specifier === '@kit.ArkTS') return { url: import.meta.url, shortCircuit: true };
      if (context.parentURL === worker && specifier === '../core/SessionSnapshot')
        return { url: new URL(specifier + '.ts', worker).href, shortCircuit: true };
      return next(specifier, context);
    },
    load(url, context, next) {
      if (url !== worker) return next(url, context);
      const code = readFileSync(new URL(url), 'utf8').replace(/^@Concurrent$/m, '');
      return { format: 'module', source: stripTypeScriptTypes(code), shortCircuit: true };
    }
  });
}
