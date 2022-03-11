package org.apache.doris.udf.func;

import org.apache.doris.proto.FunctionService;

import java.util.HashMap;
import java.util.Map;
import java.util.ServiceLoader;

/**
 * @author siu
 */
public class Functions {

    /**
     *  函数实现
     */
    private static final Map<String, IFunction> FUNCTION_MAP = new HashMap<>(16);

    // region singleton

    private static Functions functions;
    private Functions() {
    }
    public static Functions get() {
        if (functions == null) {
            synchronized (Functions.class) {
                if (functions == null) {
                    functions = new Functions();
                    loadFunctionMap();
                }
            }
        }
        return functions;
    }
    // endregion

    /**
     * load function from SPI
     */
    private static void loadFunctionMap() {
        ServiceLoader<IFunction> fs = ServiceLoader.load(IFunction.class);
        for (IFunction f : fs) {
            FUNCTION_MAP.put(f.getName(), f);
        }
    }

    /**
     * 计算请求的函数
     *
     * @param request 函数请求参数
     * @return 函数计算结果
     */
    public FunctionService.PFunctionCallResponse call(FunctionService.PFunctionCallRequest request) {
        String functionName = request.getFunctionName();
        IFunction function = FUNCTION_MAP.get(functionName);
        return function.call(request);
    }

    public boolean check(FunctionService.PCheckFunctionRequest request) {
        String functionName = request.getFunction().getFunctionName();
        IFunction function = FUNCTION_MAP.get(functionName);
        return function.check(request);
    }
}