public class JSONPlaceholderExercise {

    private static CCA_Integration__mdt config = [SELECT Id, base_url__c, TimeoutDuration__c FROM CCA_Integration__mdt LIMIT 1];    
    private static String base_url = config.base_url__c; 
    private static Integer timeout_duration = config.TimeoutDuration__c.intValue();

    /* this doesn't work because it's all static methods
     * Could change to non static, but to keep it as close to the original, 
     * will just set the values directly as class level variables
     * 
    public JSONPlaceholderExercise() {
        fetchEndpointParams(); 
    }
        
    private static void fetchEndpointParams() {
        try {
            CCA_Integration__mdt config = [SELECT Id, base_url__c FROM CCA_Integration__mdt LIMIT 1];
            base_url = config.base_url__c; 
            timeout_duration = config.TimeoutDuration__c.intValue();
        } catch (Exception e) {
            throw new JSONPlaceholderExerciseCustomException('Error fetching base URL: ' + e.getMessage());
        }
    }
    */

    /**
     * Shared method to build the HttpRequest
     * @param path - path to add to base_url
     * @param method - GET, POST, etc...
     * @param body - request body as a JSON string; if not needed then pass in null
     * @return HttpRequest for the callout
     */
    private static HttpRequest buildRequest(String path, String method, String body) {
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint(base_url + path);
        req.setMethod(method);
        req.setTimeout(timeout_duration);
        if(body != null) {
            req.setBody(body);
        }
        return req;
    }
  
    /**
     * Exercise 1: Implement a GET request to fetch a post by ID
     * Endpoint: /posts/{postId}
     * @param postId - The ID of the post to fetch
     * @return String - The JSON response from the API
     */
    public static String getPostById(Integer postId) {
        if(postId != null) {
            HttpRequest req = buildRequest('/posts/' + postId, 'GET', null);
            HttpResponse res = sendCallout(req);
            return handleResponse(res);
        } else{
            throw new JSONPlaceholderExerciseCustomException(
                'Missing postId parameter: cant fetchById without an Id!'
            );
        }
    }
    
    /**
     * Exercise 2: Implement a POST request to create a new post
     * Endpoint: /posts
     * @param title - The title of the post
     * @param body - The body content of the post
     * @param userId - The user ID creating the post
     * @return String - The JSON response from the API
     */
    public static String createPost(String title, String body, Integer userId) {
        Map<String, Object> rqBody = new Map<String, Object>{
            'title' => title,
            'body' => body,
            'userId' => userId
        };
        HttpRequest req = buildRequest('/posts', 'POST', JSON.serialize(rqBody)); 
        HttpResponse res = sendCallout(req);
        return handleResponse(res);
    }

    /**
     * Method to bulkify and handle multiple posts
     * TODO additional work would be needed to bulkify this over 100
     * @param newPosts - list of wrappers with details for each post
     * @return List<String> - list of JSON responses from API
     */
    public static List<String> createPosts(List<newPostRQ> newPosts) {
        if(newPosts.size() < 99) {
            List<String> postIDs = new List<String>();
            for(newPostRQ newPost : newPosts) {
                postIDs.add( createPost(newPost.title, newPost.body, newPost.userId) );
            }
            return postIDs;
        } else {
            throw new JSONPlaceholderExerciseCustomException('too many requests, write yourself a batch class son!');
        }
    }
    
    /**
     * Exercise 3: Implement a PUT request to update a post
     * Endpoint: /posts/{postId}
     * @param postId - The ID of the post to update
     * @param title - The new title
     * @param body - The new body content
     * @param userId - The user ID
     * @return String - The JSON response from the API
     */
    public static String updatePost(Integer postId, String title, String body, Integer userId) {
        Map<String, Object> rqBody = new Map<String, Object>{
            'postId' => postId,
            'title' => title,
            'body' => body,
            'userId' => userId
        };
        HttpRequest req = buildRequest('/posts/' + postId, 'PUT', JSON.serialize(rqBody)); 
        HttpResponse res = sendCallout(req);
        return handleResponse(res);
    }
    
    /**
     * Exercise 4: Implement a PATCH request to partially update a post
     * Endpoint: /posts/{postId}
     * @param postId - The ID of the post to patch
     * @param title - The new title (can be null)
     * @return String - The JSON response from the API
     */
    public static String patchPostTitle(Integer postId, String title) {
        Map<String, Object> rqBody = new Map<String, Object>{
            'title' => title
        };
        HttpRequest req = buildRequest('/posts/' + postId, 'PATCH', JSON.serialize(rqBody));
        HttpResponse res = sendCallout(req);
        return handleResponse(res);
    }
    
    /**
     * Exercise 5: Implement a DELETE request to remove a post
     * Endpoint: /posts/{postId}
     * @param postId - The ID of the post to delete
     * @return Integer - The HTTP status code from the response
     */
    public static Integer deletePost(Integer postId) {
        HttpRequest req = buildRequest('/posts/' + postId, 'DELETE', null);
        HttpResponse res = sendCallout(req);
        // TODO if I return the body, test still passes
        // if we need to return status code integer, test should fail if I accidentally return body
        return res.getStatusCode();
    }

    /**
     * Shared method to check response status code
     * @param statusCode - status code integer of the HttpResponse
     * @return Boolean - true false to tell if callout was successful
     */
    private static Boolean statusCodeIsSuccessful(Integer statusCode) {
        return (statusCode >= 200 && statusCode <= 299);
    }

    /**
     * Shared method to return response body when callout was successful
     * Returns response body when successful
     * If callout not successful, throws exception with status cody and body
     * @param res - HttpResponse
     * @return String - return the response body as a string
     */
    private static String handleResponse(HttpResponse res) {
        Integer statusCode = res.getStatusCode(); 
        if(statusCodeIsSuccessful(statusCode)) {
            return res.getBody();
        } else {
            String errorMsg = 'Callout failed. Status Code: ' + statusCode + 
                              '; Response: ' + res.getBody();
            throw new JSONPlaceholderExerciseCustomException(errorMsg); 
        }
    }

    /**
     * Shared method that performs the actual callout, http send
     * @param req - HttpRequest callout request
     * @return HttpResponse callout response
     */
    private static HttpResponse sendCallout(HttpRequest req) {
        try {
            return new Http().send(req);
        } catch(Exception calloutError) {
            throw new JSONPlaceholderExerciseCustomException(calloutError.getMessage()); 
        }
    }

    /**
     * wrapper class to bulkify new posts
     */
    public class NewPostRQ {
        public String title;
        public String body;
        public Integer userId;
    }

    /**
     * custom exception for errors from JSONPlaceholderExercise callouts
     */
    public class JSONPlaceholderExerciseCustomException extends Exception {
    }

} 