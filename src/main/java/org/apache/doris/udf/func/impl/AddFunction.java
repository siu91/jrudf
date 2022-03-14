package org.apache.doris.udf.func.impl;

import org.apache.doris.proto.FunctionService;
import org.apache.doris.proto.Types;
import org.apache.doris.udf.func.IFunction;

import javax.annotation.Nonnull;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

/**
 * @author siu
 */
public class AddFunction implements IFunction {
    @Nonnull
    @Override
    public String getName() {
        return "add_init";
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
                            .addAllInt32Value(IntStream.range(0, Math.min(request.getArgs(0)
                                    .getInt32ValueCount(), request.getArgs(1).getInt32ValueCount()))
                                    .mapToObj(i -> request.getArgs(0).getInt32Value(i) + request.getArgs(1)
                                            .getInt32Value(i)).collect(Collectors.toList()))
                            .setType(Types.PGenericType.newBuilder().setId(Types.PGenericType.TypeId.INT32).build())
                            .build()).build();
        } else {
            res = FunctionService.PFunctionCallResponse.newBuilder()
                    .setStatus(Types.PStatus.newBuilder().setStatusCode(1).build()).build();
        }
        return res;
    }
}
