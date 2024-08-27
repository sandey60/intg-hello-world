package org.wso2.carbon.connector.integration.test.helloWorld;

import org.json.JSONObject;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;
import org.wso2.connector.integration.test.base.ConnectorIntegrationTestBase;
import org.wso2.connector.integration.test.base.RestResponse;

import java.util.HashMap;
import java.util.Map;

/**
 * Sample integration test
 */
public class helloWorldConnectorIntegrationTest extends ConnectorIntegrationTestBase {

    private Map<String, String> eiRequestHeadersMap = new HashMap<String, String>();
    private Map<String, String> apiRequestHeadersMap = new HashMap<String, String>();

    @BeforeClass(alwaysRun = true)
    public void setEnvironment() throws Exception {

        String connectorName = System.getProperty("connector_name") + "-connector-" +
                System.getProperty("connector_version") + ".zip";
        init(connectorName);

        eiRequestHeadersMap.put("Accept-Charset", "UTF-8");
        eiRequestHeadersMap.put("Content-Type", "application/json");
    }

    @Test(enabled = true, groups = { "wso2.ei" }, description = "helloWorld test case")
    public void testSample() throws Exception {
        log.info("Successfully tested");
        RestResponse<JSONObject> eiRestResponse = sendJsonRestRequest(proxyUrl, "POST", eiRequestHeadersMap,
                "sampleRequest.json");
    }
}
