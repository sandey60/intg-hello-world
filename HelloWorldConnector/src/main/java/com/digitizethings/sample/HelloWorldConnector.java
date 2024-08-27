package com.digitizethings.sample;

import org.apache.synapse.MessageContext;
import org.json.simple.JSONObject;
import org.wso2.carbon.connector.core.AbstractConnector;
import org.wso2.carbon.connector.core.ConnectException;

/**
 * Sample method implementation.
 */
public class HelloWorldConnector extends AbstractConnector {

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
            messageContext.setProperty("responseBody", "" + response);
        } catch (Exception e) {
            throw new ConnectException(e);
        }
    }
}
