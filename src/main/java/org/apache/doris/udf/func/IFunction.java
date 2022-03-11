package org.apache.doris.udf.func;

import org.apache.doris.proto.FunctionService;

import javax.annotation.Nonnull;

/**
 * @author siu
 */
public interface IFunction {
    /**
     * 函数名称
     *
     * @return 函数名
     */
    @Nonnull
    String getName();

    /**
     * 检查
     *
     * @param request 检查参数
     * @return ture 通过
     */
    boolean check(FunctionService.PCheckFunctionRequest request);

    /**
     * 函数调用
     *
     * @param request 调用参数
     * @return 计算结果
     */
    FunctionService.PFunctionCallResponse call(FunctionService.PFunctionCallRequest request);
}
