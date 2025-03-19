({
	doInit : function(component, event, helper) {
        console.log('doInit: START');
        
        //component.set("v.body",null);
		helper.initComponent(component, event, helper);
        
        console.log('doInit: END');
	},
    statusChange : function (component, event, helper) {
        console.log('statusChange: START');
        
    	if (event.getParam('status') === "FINISHED") {
        	console.log('statusChange: finished status');
			helper.navigate2target(component, event, helper);
            /*let outputVar = event.getParam("outputVariables");
        	console.log('statusChange: outputVar fetched',outputVar);
            
      		let target = component.get("v.target");
        	console.log('statusChange: target fetched',target);
            
            let targetId = null;
            outputVar.forEach(function(item) {
                if (item.name == target) targetId = item.value;
            });
            if (!targetId) {
        		console.warn('statusChange: no targetId found');
                return;
            }
        	console.log('statusChange: targetId fetched',targetId);
            
  	                
            let navService = component.find("navService");

            	let pageReference = {
            	"type": "standard__recordPage",
       			"attributes": {
           			"recordId": targetId,
           			"actionName": "view"
       			}
        	};

            navService.navigate(pageReference);
        	console.log('statusChange: navigation triggered',pageReference);
         
            
            var wkAPI = component.find("workspaceUtil");
        	console.log('statusChange: wkAPI',wkAPI);
            
			wkAPI.isConsoleNavigation().then(function(consoleMode) {
            	console.log('statusChange: console mode',consoleMode);
            	if (consoleMode) return wkAPI.getEnclosingTabId();
        	}).then(function(tabId){
            	console.log('statusChange: closing tab ',tabId);
                return wkAPI.closeTab({'tabId':tabId});
            }).catch(function(error) {
            	console.error('statusChange: error raised',JSON.stringify(error));
        	});*/
                
    	}
        else {
        	console.log('statusChange: other status',JSON.stringify(event.getParams()));
        }
        console.log('statusChange: END');
    }
})