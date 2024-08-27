/*
*  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
*
*  WSO2 Inc. licenses this file to you under the Apache License,
*  Version 2.0 (the "License"); you may not use this file except
*  in compliance with the License.
*  You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing,
* software distributed under the License is distributed on an
* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
* KIND, either express or implied.  See the License for the
* specific language governing permissions and limitations
* under the License.
*/
package org.wso2.carbon.esb.connector;

import org.apache.synapse.MessageContext;
import org.json.simple.JSONObject;
import org.wso2.carbon.connector.core.AbstractConnector;
import org.wso2.carbon.connector.core.ConnectException;

/**
 * Sample method implementation.
 */
public class helloWorldConnector extends AbstractConnector {

    @Override
    public void connect(MessageContext messageContext) throws ConnectException {
        Object templateParam = getParameter(messageContext, "generated_param");
        try {
            log.info("hello-world sample connector received message :" + templateParam);
            String orderId = (String) messageContext.getProperty("orderId");
            log.info("Order got fulfilled for id ::: " + orderId);
            String responseMsg = "Order got fulfilled for order id " + orderId;
            JSONObject response = new JSONObject();
            response.put("status", responseMsg);
            log.info("response ::: " + response);
            messageContext.setProperty("responseBody", response);
        } catch (Exception e) {
            throw new ConnectException(e);
        }
    }
}