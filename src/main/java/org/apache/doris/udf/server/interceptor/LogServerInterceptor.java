package org.apache.doris.udf.server.interceptor;

import io.grpc.*;

import java.util.logging.Logger;

/**
 * @author siu
 */
public class LogServerInterceptor implements ServerInterceptor {
    private static final Logger logger = Logger.getLogger(LogServerInterceptor.class.getName());

    @Override
    public <ReqT, RespT> ServerCall.Listener<ReqT> interceptCall(ServerCall<ReqT, RespT> serverCall, Metadata metadata, ServerCallHandler<ReqT, RespT> serverCallHandler) {
        logger.info("serverCall=" +  serverCall.toString());
        logger.info("metadata=" +  metadata.toString());
        CustomServerCall<ReqT, RespT> customServerCall = new CustomServerCall<>(serverCall);
        ServerCall.Listener<ReqT> listener = serverCallHandler.startCall(customServerCall, metadata);
        return new CustomServerCallListener<>(listener);
    }


    static class CustomServerCallListener<ReqT> extends ForwardingServerCallListener.SimpleForwardingServerCallListener<ReqT> {

        protected CustomServerCallListener(ServerCall.Listener<ReqT> delegate) {
            super(delegate);
        }
    }


    static class CustomServerCall<ReqT, RespT> extends ForwardingServerCall.SimpleForwardingServerCall<ReqT, RespT> {

        protected CustomServerCall(ServerCall<ReqT, RespT> delegate) {
            super(delegate);
        }
    }


}
