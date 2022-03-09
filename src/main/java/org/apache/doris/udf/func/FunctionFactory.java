package org.apache.doris.udf.func;

import org.apache.doris.proto.FunctionService;
import org.apache.doris.proto.Types;

import java.util.stream.Collectors;
import java.util.stream.IntStream;

/**
 * @author siu
 */
public class FunctionFactory {

    public static FunctionService.PFunctionCallResponse response(FunctionService.PFunctionCallRequest request) {
        String functionName = request.getFunctionName();
        FunctionService.PFunctionCallResponse res;
        if ("add_int".equals(functionName)) {
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
