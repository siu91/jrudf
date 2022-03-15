package com.siu.udf;

import org.apache.doris.proto.FunctionService;
import org.apache.doris.proto.Types;
import org.apache.doris.udf.func.IFunction;

import java.util.stream.Collectors;
import java.util.stream.IntStream;

/**
 * @author siu
 */
public class StringLengthFunction implements IFunction {
    @Override
    public String getName() {
        return "str_length";
    }

    @Override
    public boolean check(FunctionService.PCheckFunctionRequest request) {
        return true;
    }


    @Override
    public FunctionService.PFunctionCallResponse call(FunctionService.PFunctionCallRequest request) {
        String functionName = request.getFunctionName();
        FunctionService.PFunctionCallResponse res;
        if (this.getName().equals(functionName)) {
            res = FunctionService.PFunctionCallResponse.newBuilder()
                    .setStatus(Types.PStatus.newBuilder().setStatusCode(0).build())
                    .setResult(Types.PValues.newBuilder().setHasNull(false)
                            .addAllInt32Value(
                                    IntStream.range(0, Math.max(0, request.getArgs(0).getStringValueCount()))
                                            .mapToObj(i -> request.getArgs(0).getStringValue(i).length())
                                            .collect(Collectors.toList()))
                            .setType(Types.PGenericType.newBuilder().setId(Types.PGenericType.TypeId.INT32).build())
                            .build()).build();
        } else {
            res = FunctionService.PFunctionCallResponse.newBuilder()
                    .setStatus(Types.PStatus.newBuilder().setStatusCode(1).build()).build();
        }
        return res;
    }
}
