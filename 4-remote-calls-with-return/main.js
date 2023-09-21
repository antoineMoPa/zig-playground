let memory;
let bufferPointer;
let instructions = [];
let lastExpressionResult = null;
// Instruction write pointer
let iwp = instructions;

// Must match definitions in native code
const TYPE_NULL = 0;
const TYPE_FLOAT = 1;

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
        getLastExpressionFloatResult: () => {
            return lastExpressionResult;
        },
        closeExpression: () => {
            let retVal = 0;
            let retType = 0;
            // When we receive a closing parenthesis,
            // we compute the operation and replace the
            // current expression by its return value.
            if (iwp[0] === '+') {
                let items = iwp.slice(1);
                let result = items.reduce((acc, val) => acc + val, 0);
                iwp.__parent[iwp.__parent.length - 1] = result;

                retVal = result;
                retType = TYPE_FLOAT;
            }
            else if (iwp.length > 0) {
                let path = iwp[0].split('.');
                let object = window;
                while(path.length > 0) {
                        let property = path.shift();
                    object = object[property];
                }
                let result = object(...iwp.slice(1));;
                iwp.__parent[iwp.__parent.length - 1] = result;
                retVal = result;
                retType = 0; // TODO determine type
            }
            // This expression is now closed and evaluated
            // Next we'll move back to processing parent expression
            if (iwp.__parent) {
                iwp = iwp.__parent;
            }

            lastExpressionResult = retVal;
            return retType;
        },
        receiveStringToken: (size) => {
            // This is basically a tiny lisp-like language reader that allows
            // wasm code to execute code in the browser context.
            const decoder = new TextDecoder("utf-8");
            const start = bufferPointer.value;
            const slice = memory.buffer.slice(start, start + size);
            const instruction = decoder.decode(slice);
            iwp.push(instruction);
        },
        receiveNumberToken: (value) => {
            iwp.push(value);
        }
    }
};

WebAssembly.instantiateStreaming(fetch("main.wasm"), importObject).then(
    (results) => {
        memory = results.instance.exports.memory;
        bufferPointer = results.instance.exports.buffer;

        results.instance.exports.main();
    },
);
