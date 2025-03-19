import readOnlyConfig from '@salesforce/apex/LWC65_GenericReadOnlyCmp.readOnlyConfig';
let data;
let origScope;
let readOnlyProfile=true;
function disableButtonsReadOnly(component,scope){
    if(data && scope == origScope) querySelectGeneric(data,component)
    else{
        readOnlyConfig({scope : scope}).then(res=>{
            console.log('response',res);
            data = res;
            readOnlyProfile = res.isReadOnlyProfile;
            if(!res.isReadOnlyProfile) return;
            querySelectGeneric(res,component);
        }).catch(err=>{
            console.error(err);
        });
    }
    origScope = scope;
    
}

function querySelectGeneric(res,component){
    setTimeout(() => {
        res.cmpType?.forEach( elType =>{
            component.template.querySelectorAll(elType).forEach(e =>{
                console.log('$$$ '+e?.label); 
                if(res.componentsExcluded &&( res.componentsExcluded.includes(e?.label) || res.componentsExcluded.includes(e?.innerHTML))) return;
                let found;
                if(elType=='button' && e?.innerHTML) res.componentsExcluded.forEach(keyword => {found = e?.innerHTML.includes(keyword)});
                if(found ) return;
                handleDatatypes(elType,e,component,res);
            })
        })
    }, 500);
}

function launchDisableMethod(component,scope){
    if(!readOnlyProfile) return;
    if(!component.ren){
        disableButtonsReadOnly(component,scope);
        component.ren = true;
    }
}
let count = 0;
function secondaryLaunch(component,scope){
    if(!readOnlyProfile) return;
    console.log('scopes'+scope+' '+origScope);
    setTimeout(() => {
        disableButtonsReadOnly(component,scope);
    }, 500);
}


function handleDatatypes(elType,ele,cmp,data){   
    switch (elType) {
        case 'lightning-datatable':
            ele.columns = ele.columns.filter(obj => (obj?.type !== 'action' && obj?.type !== 'button') || data.componentsExcluded.includes(obj?.typeAttributes?.label));
            break;
        default:
            ele.disabled = true;
            ele.style = 'pointer-events: none;display:none;';
            ele.setAttribute('aria-disabled', 'true');
            break;
    }
}

function isUserReadOnlyProfile(){
    return readOnlyProfile;
}

export {disableButtonsReadOnly,launchDisableMethod,secondaryLaunch,isUserReadOnlyProfile}