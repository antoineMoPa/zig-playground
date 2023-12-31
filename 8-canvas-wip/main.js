let memory;
let u8WasmToJSBufferPointer;
let u8JSToWasmBufferPointer;
let instructions = [];
let lastExpressionResult = null;
// Instruction write pointer
let iwp = instructions;

// Must match definitions in native code
const TYPE_NULL = 0;
const TYPE_INT_8 = 1;
const TYPE_STR = 2;

const wasmVariable = {};

// Operations used in remote calls by wasm
window._wasmVariables = {}
window._wasmOps = {
    "add": (...items) => items.reduce((acc, val) => acc + val, 0),
    "mul": (...items) => items.reduce((acc, val) => acc * val, 1),
    "set-variable": (name, value) => { window._wasmVariables[name] = value; },
    "get-variable": (name) => window._wasmVariables[name],
}

const importObject = {
    env: {
        debug(message) {
            console.log(message);
        },
        openExpression: () => {
            let arr = [];
            let parent = iwp;
            iwp.push(arr);
            iwp = arr;
            iwp.__parent = parent;
        },
        closeExpression: () => {
            let retVal = 0;
            // When we receive a closing parenthesis,
            // we compute the operation and replace the
            // current expression by its return value.
            if (iwp.length > 0) {
                let path = iwp[0].split('.');
                let object = window;
                while(path.length > 0) {
                    let property = path.shift();
                    object = object[property];
                }
                let result = object(...iwp.slice(1));
                iwp.__parent[iwp.__parent.length - 1] = result;

                retVal = result;
            }
            // This expression is now closed and evaluated
            // Next we'll move back to processing parent expression
            if (iwp.__parent) {
                iwp = iwp.__parent;
            }
            if (iwp === instructions) {
                // We are back to the top level expression, we computed everything and
                // we can erase the instructions.
                instructions.splice(0);
            }

            const mem = new Uint8Array(memory.buffer);

            if (typeof retVal === 'string') {
                const decoder = new TextEncoder();
                const arr = decoder.encode(retVal);
                mem[u8JSToWasmBufferPointer.value + 0] = TYPE_STR;
                mem[u8JSToWasmBufferPointer.value + 1] = arr.length;
                for (let i = 0; i < arr.length; i++) {
                    mem[u8JSToWasmBufferPointer.value + 2 + i] = arr[i];
                }
            } else {
                mem[u8JSToWasmBufferPointer.value + 0] = TYPE_INT_8;
                mem[u8JSToWasmBufferPointer.value + 1] = retVal;
            }
        },
        receiveStringToken: (size) => {
            // This is basically a tiny lisp-like language reader that allows
            // wasm code to execute code in the browser context.
            const decoder = new TextDecoder("utf-8");
            const start = u8WasmToJSBufferPointer.value;
            const slice = memory.buffer.slice(start, start + size);
            const instruction = decoder.decode(slice);
            iwp.push(instruction);
        },
        receiveNumberToken: (value) => {
            iwp.push(value);
        },
    }
};

WebAssembly.instantiateStreaming(fetch("main.wasm"), importObject).then(
    (results) => {
        memory = results.instance.exports.memory;
        u8WasmToJSBufferPointer = results.instance.exports.u8WasmToJSBuffer;
        u8JSToWasmBufferPointer = results.instance.exports.u8JSToWasmBuffer;

        results.instance.exports.main();
    },
);
