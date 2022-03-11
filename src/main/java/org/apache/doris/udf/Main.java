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

package org.apache.doris.udf;

import org.apache.doris.udf.func.Functions;
import org.apache.doris.udf.server.RpcServer;

import java.io.IOException;
import java.util.logging.Logger;

/**
 * @author siu
 */
public class Main {

    private static final Logger logger = Logger.getLogger(Main.class.getName());

    /**
     * Main launches the server from the command line.
     */
    public static void main(String[] args) throws IOException, InterruptedException {
        int port = 9000;
        if (args.length > 0) {
            try {
                port = Integer.parseInt(args[0]);
            } catch (NumberFormatException e) {
                System.err.println("port " + args[0] + " must be an integer.");
                System.exit(1);
            }
        }
        if (port <= 0) {
            System.err.println("port " + args[0] + " must be positive.");
            System.exit(1);
        }
        final RpcServer server = new RpcServer();
        Functions.get();
        server.start(port);
        server.blockUntilShutdown();
    }
}
