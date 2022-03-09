// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

package org.apache.doris.udf.server;

import org.apache.doris.proto.FunctionService;
import org.apache.doris.proto.PFunctionServiceGrpc;
import org.apache.doris.proto.Types;

import java.util.logging.Logger;

import io.grpc.stub.StreamObserver;
import org.apache.doris.udf.func.FunctionFactory;

/**
 * @author siu
 */
public class FunctionServiceImpl extends PFunctionServiceGrpc.PFunctionServiceImplBase {
    private static final Logger logger = Logger.getLogger(FunctionServiceImpl.class.getName());

    public static <T> void completed(StreamObserver<T> observer, T data) {
        observer.onNext(data);
        observer.onCompleted();
    }

    @Override
    public void fnCall(FunctionService.PFunctionCallRequest request,
                       StreamObserver<FunctionService.PFunctionCallResponse> responseObserver) {
        logger.info("fnCall request=" + request);
        FunctionService.PFunctionCallResponse response = FunctionFactory.response(request);
        logger.info("fnCall res=" + response);
        completed(responseObserver, response);
    }

    @Override
    public void checkFn(FunctionService.PCheckFunctionRequest request,
                        StreamObserver<FunctionService.PCheckFunctionResponse> responseObserver) {
        // symbol is functionName
        logger.info("checkFn request=" + request);
        int status = 0;
        if ("add_int".equals(request.getFunction().getFunctionName())) {
            // check inputs count
            if (request.getFunction().getInputsCount() != 2) {
                status = -1;
            }
        }
        FunctionService.PCheckFunctionResponse res =
                FunctionService.PCheckFunctionResponse.newBuilder()
                        .setStatus(Types.PStatus.newBuilder().setStatusCode(status).build()).build();
        logger.info("checkFn res=" + res);
        completed(responseObserver, res);
    }

    @Override
    public void handShake(Types.PHandShakeRequest request, StreamObserver<Types.PHandShakeResponse> responseObserver) {
        logger.info("handShake request=" + request);
        completed(responseObserver,
                Types.PHandShakeResponse.newBuilder().setStatus(Types.PStatus.newBuilder().setStatusCode(0).build())
                        .setHello(request.getHello()).build());
    }

}
