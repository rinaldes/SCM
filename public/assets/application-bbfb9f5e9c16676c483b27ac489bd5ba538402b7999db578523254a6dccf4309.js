!function(v){var e=0,b=function(){return(new Date).getTime()+e++},g=function(e){return"["+e+"]$1"},y=function(e){return"_"+e+"_$1"},w=function(e,t,a){return e?"function"==typeof e?(t&&console.warn("association-insertion-traversal is ignored, because association-insertion-node is given as a function."),e(a)):"string"==typeof e?t?a[t](e):"this"==e?a:v(e):void 0:a.parent()};v(document).on("click",".add_fields",function(e){e.preventDefault();var t=v(this),a=t.data("association"),n=t.data("associations"),r=t.data("association-insertion-template"),i=t.data("association-insertion-method")||t.data("association-insertion-position")||"before",o=t.data("association-insertion-node"),l=t.data("association-insertion-traversal"),s=parseInt(t.data("count"),10),c=new RegExp("\\[new_"+a+"\\](.*?\\s)","g"),u=new RegExp("_new_"+a+"_(\\w*)","g"),d=b(),f=r.replace(c,g(d)),m=[],h=e;for(f==r&&(c=new RegExp("\\[new_"+n+"\\](.*?\\s)","g"),u=new RegExp("_new_"+n+"_(\\w*)","g"),f=r.replace(c,g(d))),m=[f=f.replace(u,y(d))],s=isNaN(s)?1:Math.max(s,1),s-=1;s;)d=b(),f=(f=r.replace(c,g(d))).replace(u,y(d)),m.push(f),s-=1;var p=w(o,l,t);p&&0!=p.length||console.warn("Couldn't find the element to insert the template. Make sure your `data-association-insertion-*` on `link_to_add_association` is correct."),v.each(m,function(e,t){var a=v(t),n=jQuery.Event("cocoon:before-insert");if(p.trigger(n,[a,h]),!n.isDefaultPrevented()){p[i](a);p.trigger("cocoon:after-insert",[a,h])}})}),v(document).on("click",".remove_fields.dynamic, .remove_fields.existing",function(e){var t=v(this),a=t.data("wrapper-class")||"nested-fields",n=t.closest("."+a),r=n.parent(),i=e;e.preventDefault(),e.stopPropagation();var o=jQuery.Event("cocoon:before-remove");if(r.trigger(o,[n,i]),!o.isDefaultPrevented()){var l=r.data("remove-timeout")||0;setTimeout(function(){t.hasClass("dynamic")?n.detach():(t.prev("input[type=hidden]").val("1"),n.hide()),r.trigger("cocoon:after-remove",[n,i])},l)}}),v(document).on("ready page:load turbolinks:load",function(){v(".remove_fields.existing.destroyed").each(function(){var e=v(this),t=e.data("wrapper-class")||"nested-fields";e.closest("."+t).hide()})})}(jQuery),function(u,s){"use strict";var c;u.rails!==s&&u.error("jquery-ujs has already been loaded!");var e=u(document);u.rails=c={linkClickSelector:"a[data-confirm], a[data-method], a[data-remote]:not([disabled]), a[data-disable-with], a[data-disable]",buttonClickSelector:"button[data-remote]:not([form]):not(form button), button[data-confirm]:not([form]):not(form button)",inputChangeSelector:"select[data-remote], input[data-remote], textarea[data-remote]",formSubmitSelector:"form",formInputClickSelector:"form input[type=submit], form input[type=image], form button[type=submit], form button:not([type]), input[type=submit][form], input[type=image][form], button[type=submit][form], button[form]:not([type])",disableSelector:"input[data-disable-with]:enabled, button[data-disable-with]:enabled, textarea[data-disable-with]:enabled, input[data-disable]:enabled, button[data-disable]:enabled, textarea[data-disable]:enabled",enableSelector:"input[data-disable-with]:disabled, button[data-disable-with]:disabled, textarea[data-disable-with]:disabled, input[data-disable]:disabled, button[data-disable]:disabled, textarea[data-disable]:disabled",requiredInputSelector:"input[name][required]:not([disabled]), textarea[name][required]:not([disabled])",fileInputSelector:"input[name][type=file]:not([disabled])",linkDisableSelector:"a[data-disable-with], a[data-disable]",buttonDisableSelector:"button[data-remote][data-disable-with], button[data-remote][data-disable]",csrfToken:function(){return u("meta[name=csrf-token]").attr("content")},csrfParam:function(){return u("meta[name=csrf-param]").attr("content")},CSRFProtection:function(e){var t=c.csrfToken();t&&e.setRequestHeader("X-CSRF-Token",t)},refreshCSRFTokens:function(){u('form input[name="'+c.csrfParam()+'"]').val(c.csrfToken())},fire:function(e,t,a){var n=u.Event(t);return e.trigger(n,a),!1!==n.result},confirm:function(e){return confirm(e)},ajax:function(e){return u.ajax(e)},href:function(e){return e[0].href},isRemote:function(e){return e.data("remote")!==s&&!1!==e.data("remote")},handleRemote:function(n){var e,t,a,r,i,o;if(c.fire(n,"ajax:before")){if(r=n.data("with-credentials")||null,i=n.data("type")||u.ajaxSettings&&u.ajaxSettings.dataType,n.is("form")){e=n.data("ujs:submit-button-formmethod")||n.attr("method"),t=n.data("ujs:submit-button-formaction")||n.attr("action"),a=u(n[0]).serializeArray();var l=n.data("ujs:submit-button");l&&(a.push(l),n.data("ujs:submit-button",null)),n.data("ujs:submit-button-formmethod",null),n.data("ujs:submit-button-formaction",null)}else n.is(c.inputChangeSelector)?(e=n.data("method"),t=n.data("url"),a=n.serialize(),n.data("params")&&(a=a+"&"+n.data("params"))):n.is(c.buttonClickSelector)?(e=n.data("method")||"get",t=n.data("url"),a=n.serialize(),n.data("params")&&(a=a+"&"+n.data("params"))):(e=n.data("method"),t=c.href(n),a=n.data("params")||null);return o={type:e||"GET",data:a,dataType:i,beforeSend:function(e,t){if(t.dataType===s&&e.setRequestHeader("accept","*/*;q=0.5, "+t.accepts.script),!c.fire(n,"ajax:beforeSend",[e,t]))return!1;n.trigger("ajax:send",e)},success:function(e,t,a){n.trigger("ajax:success",[e,t,a])},complete:function(e,t){n.trigger("ajax:complete",[e,t])},error:function(e,t,a){n.trigger("ajax:error",[e,t,a])},crossDomain:c.isCrossDomain(t)},r&&(o.xhrFields={withCredentials:r}),t&&(o.url=t),c.ajax(o)}return!1},isCrossDomain:function(e){var t=document.createElement("a");t.href=location.href;var a=document.createElement("a");try{return a.href=e,a.href=a.href,!((!a.protocol||":"===a.protocol)&&!a.host||t.protocol+"//"+t.host==a.protocol+"//"+a.host)}catch(n){return!0}},handleMethod:function(e){var t=c.href(e),a=e.data("method"),n=e.attr("target"),r=c.csrfToken(),i=c.csrfParam(),o=u('<form method="post" action="'+t+'"></form>'),l='<input name="_method" value="'+a+'" type="hidden" />';i===s||r===s||c.isCrossDomain(t)||(l+='<input name="'+i+'" value="'+r+'" type="hidden" />'),n&&o.attr("target",n),o.hide().append(l).appendTo("body"),o.submit()},formElements:function(e,t){return e.is("form")?u(e[0].elements).filter(t):e.find(t)},disableFormElements:function(e){c.formElements(e,c.disableSelector).each(function(){c.disableFormElement(u(this))})},disableFormElement:function(e){var t,a;t=e.is("button")?"html":"val",(a=e.data("disable-with"))!==s&&(e.data("ujs:enable-with",e[t]()),e[t](a)),e.prop("disabled",!0),e.data("ujs:disabled",!0)},enableFormElements:function(e){c.formElements(e,c.enableSelector).each(function(){c.enableFormElement(u(this))})},enableFormElement:function(e){var t=e.is("button")?"html":"val";e.data("ujs:enable-with")!==s&&(e[t](e.data("ujs:enable-with")),e.removeData("ujs:enable-with")),e.prop("disabled",!1),e.removeData("ujs:disabled")},allowAction:function(e){var t,a=e.data("confirm"),n=!1;if(!a)return!0;if(c.fire(e,"confirm")){try{n=c.confirm(a)}catch(r){(console.error||console.log).call(console,r.stack||r)}t=c.fire(e,"confirm:complete",[n])}return n&&t},blankInputs:function(e,t,a){var n,r,i,o=u(),l=t||"input,textarea",s=e.find(l),c={};return s.each(function(){(n=u(this)).is("input[type=radio]")?(i=n.attr("name"),c[i]||(0===e.find('input[type=radio]:checked[name="'+i+'"]').length&&(r=e.find('input[type=radio][name="'+i+'"]'),o=o.add(r)),c[i]=i)):(n.is("input[type=checkbox],input[type=radio]")?n.is(":checked"):!!n.val())===a&&(o=o.add(n))}),!!o.length&&o},nonBlankInputs:function(e,t){return c.blankInputs(e,t,!0)},stopEverything:function(e){return u(e.target).trigger("ujs:everythingStopped"),e.stopImmediatePropagation(),!1},disableElement:function(e){var t=e.data("disable-with");t!==s&&(e.data("ujs:enable-with",e.html()),e.html(t)),e.bind("click.railsDisable",function(e){return c.stopEverything(e)}),e.data("ujs:disabled",!0)},enableElement:function(e){e.data("ujs:enable-with")!==s&&(e.html(e.data("ujs:enable-with")),e.removeData("ujs:enable-with")),e.unbind("click.railsDisable"),e.removeData("ujs:disabled")}},c.fire(e,"rails:attachBindings")&&(u.ajaxPrefilter(function(e,t,a){e.crossDomain||c.CSRFProtection(a)}),u(window).on("pageshow.rails",function(){u(u.rails.enableSelector).each(function(){var e=u(this);e.data("ujs:disabled")&&u.rails.enableFormElement(e)}),u(u.rails.linkDisableSelector).each(function(){var e=u(this);e.data("ujs:disabled")&&u.rails.enableElement(e)})}),e.on("ajax:complete",c.linkDisableSelector,function(){c.enableElement(u(this))}),e.on("ajax:complete",c.buttonDisableSelector,function(){c.enableFormElement(u(this))}),e.on("click.rails",c.linkClickSelector,function(e){var t=u(this),a=t.data("method"),n=t.data("params"),r=e.metaKey||e.ctrlKey;if(!c.allowAction(t))return c.stopEverything(e);if(!r&&t.is(c.linkDisableSelector)&&c.disableElement(t),c.isRemote(t)){if(r&&(!a||"GET"===a)&&!n)return!0;var i=c.handleRemote(t);return!1===i?c.enableElement(t):i.fail(function(){c.enableElement(t)}),!1}return a?(c.handleMethod(t),!1):void 0}),e.on("click.rails",c.buttonClickSelector,function(e){var t=u(this);if(!c.allowAction(t)||!c.isRemote(t))return c.stopEverything(e);t.is(c.buttonDisableSelector)&&c.disableFormElement(t);var a=c.handleRemote(t);return!1===a?c.enableFormElement(t):a.fail(function(){c.enableFormElement(t)}),!1}),e.on("change.rails",c.inputChangeSelector,function(e){var t=u(this);return c.allowAction(t)&&c.isRemote(t)?(c.handleRemote(t),!1):c.stopEverything(e)}),e.on("submit.rails",c.formSubmitSelector,function(e){var t,a,n=u(this),r=c.isRemote(n);if(!c.allowAction(n))return c.stopEverything(e);if(n.attr("novalidate")===s)if(n.data("ujs:formnovalidate-button")===s){if((t=c.blankInputs(n,c.requiredInputSelector,!1))&&c.fire(n,"ajax:aborted:required",[t]))return c.stopEverything(e)}else n.data("ujs:formnovalidate-button",s);if(r){if(a=c.nonBlankInputs(n,c.fileInputSelector)){setTimeout(function(){c.disableFormElements(n)},13);var i=c.fire(n,"ajax:aborted:file",[a]);return i||setTimeout(function(){c.enableFormElements(n)},13),i}return c.handleRemote(n),!1}setTimeout(function(){c.disableFormElements(n)},13)}),e.on("click.rails",c.formInputClickSelector,function(e){var t=u(this);if(!c.allowAction(t))return c.stopEverything(e);var a=t.attr("name"),n=a?{name:a,value:t.val()}:null,r=t.closest("form");0===r.length&&(r=u("#"+t.attr("form"))),r.data("ujs:submit-button",n),r.data("ujs:formnovalidate-button",t.attr("formnovalidate")),r.data("ujs:submit-button-formaction",t.attr("formaction")),r.data("ujs:submit-button-formmethod",t.attr("formmethod"))}),e.on("ajax:send.rails",c.formSubmitSelector,function(e){this===e.target&&c.disableFormElements(u(this))}),e.on("ajax:complete.rails",c.formSubmitSelector,function(e){this===e.target&&c.enableFormElements(u(this))}),u(function(){c.refreshCSRFTokens()}))}(jQuery),function(){}.call(this),function(){jQuery(function(){var e,t,a,n,r;return a=$("#area_city_id :selected").text(),e=$("#area_city_id").html(),$("#area_city_id").parent().hide(),0!==a.length&&(r=$("#area_regional_id :selected").text(),t=r.replace(/([ #;&,.+*~\':"!^$[\]()=>|\/@])/g,"\\$1"),n=$(e).filter("optgroup[label="+t+"]").html(),$("#area_city_id").html(n),$("#area_city_id").parent().show()),console.log(e),$("#area_regional_id").change(function(){return r=$("#area_regional_id :selected").text(),t=r.replace(/([ #;&,.+*~\':"!^$[\]()=>|\/@])/g,"\\$1"),n=$(e).filter("optgroup[label="+t+"]").html(),console.log(n),n?($("#area_city_id").html(n),$("#area_city_id").parent().show()):$("#area_city_id").empty()})})}.call(this),function(){jQuery(function(){var a;return a=$("#branch_city_name").html(),$("#branch_province_id").change(function(){var e,t;return t=$("#branch_province_id :selected").text(),(e=$(a).filter("optgroup[label='"+t+"']").html())?$("#branch_city_name").html(e):$("#branch_city_name").empty()})})}.call(this),function(){}.call(this),function(){jQuery(function(){var a;return a=$("#head_office_city_name").html(),$("#head_office_province").change(function(){var e,t;return t=$("#head_office_province :selected").text(),(e=$(a).filter("optgroup[label='"+t+"']").html())?$("#head_office_city_name").html(e):$("#head_office_city_name").empty()})})}.call(this),function(){}.call(this),function(y){"use strict";y.browser||(y.browser={},y.browser.mozilla=/mozilla/.test(navigator.userAgent.toLowerCase())&&!/webkit/.test(navigator.userAgent.toLowerCase()),y.browser.webkit=/webkit/.test(navigator.userAgent.toLowerCase()),y.browser.opera=/opera/.test(navigator.userAgent.toLowerCase()),y.browser.msie=/msie/.test(navigator.userAgent.toLowerCase()));var t={destroy:function(){return y(this).unbind(".maskMoney"),y.browser.msie&&(this.onpaste=null),this},mask:function(a){return this.each(function(){var e,t=y(this);return"number"==typeof a&&(t.trigger("mask"),e=y(t.val().split(/\D/)).last()[0].length,a=a.toFixed(e),t.val(a)),t.trigger("mask")})},unmasked:function(){return this.map(function(){var a,e=y(this).val()||"0",t=-1!==e.indexOf("-");return y(e.split(/\D/).reverse()).each(function(e,t){if(t)return a=t,!1}),e=(e=e.replace(/\D/g,"")).replace(new RegExp(a+"$"),"."+a),t&&(e="-"+e),parseFloat(e)})},init:function(g){return g=y.extend({prefix:"",suffix:"",affixesStay:!0,thousands:",",decimal:".",precision:2,allowZero:!1,allowNegative:!1},g),this.each(function(){function l(){var e,t,a,n,r,i=b.get(0),o=0,l=0;return"number"==typeof i.selectionStart&&"number"==typeof i.selectionEnd?(o=i.selectionStart,l=i.selectionEnd):(t=document.selection.createRange())&&t.parentElement()===i&&(n=i.value.length,e=i.value.replace(/\r\n/g,"\n"),(a=i.createTextRange()).moveToBookmark(t.getBookmark()),(r=i.createTextRange()).collapse(!1),-1<a.compareEndPoints("StartToEnd",r)?o=l=n:(o=-a.moveStart("character",-n),o+=e.slice(0,o).split("\n").length-1,-1<a.compareEndPoints("EndToEnd",r)?l=n:(l=-a.moveEnd("character",-n),l+=e.slice(0,l).split("\n").length-1))),{start:o,end:l}}function s(){var e=!(b.val().length>=b.attr("maxlength")&&0<=b.attr("maxlength")),t=l(),a=t.start,n=t.end,r=!(t.start===t.end||!b.val().substring(a,n).match(/\d/)),i="0"===b.val().substring(0,1);return e||r||i}function a(n){b.each(function(e,t){if(t.setSelectionRange)t.focus(),t.setSelectionRange(n,n);else if(t.createTextRange){var a=t.createTextRange();a.collapse(!0),a.moveEnd("character",n),a.moveStart("character",n),a.select()}})}function c(e){var t="";return-1<e.indexOf("-")&&(e=e.replace("-",""),t="-"),t+g.prefix+e+g.suffix}function n(e){var t,a,n,r=-1<e.indexOf("-")&&g.allowNegative?"-":"",i=e.replace(/[^0-9]/g,""),o=i.slice(0,i.length-g.precision);return""===(o=(o=o.replace(/^0*/g,"")).replace(/\B(?=(\d{3})+(?!\d))/g,g.thousands))&&(o="0"),t=r+o,0<g.precision&&(a=i.slice(i.length-g.precision),n=new Array(g.precision+1-a.length).join(0),t+=g.decimal+n+a),c(t)}function u(e){var t=b.val().length;b.val(n(b.val())),a(e-=t-b.val().length)}function r(){var e=b.val();b.val(n(e))}function d(){var e=b.val();return g.allowNegative?""!==e&&"-"===e.charAt(0)?e.replace("-",""):"-"+e:e}function f(e){e.preventDefault?e.preventDefault():e.returnValue=!1}function i(e){var t,a,n,r,i,o=(e=e||window.event).which||e.charCode||e.keyCode;return o!==undefined&&(o<48||57<o?45===o?(b.val(d()),!1):43===o?(b.val(b.val().replace("-","")),!1):(13===o||9===o||(!y.browser.mozilla||37!==o&&39!==o||0!==e.charCode)&&f(e),!0):(s()&&(f(e),t=String.fromCharCode(o),n=(a=l()).start,r=a.end,i=b.val(),b.val(i.substring(0,n)+t+i.substring(r,i.length)),u(n+1)),!1))}function e(e){var t,a,n,r,i,o=(e=e||window.event).which||e.charCode||e.keyCode;return o!==undefined&&(a=(t=l()).start,n=t.end,8!==o&&46!==o&&63272!==o||(f(e),r=b.val(),a===n&&(8===o?""===g.suffix?a-=1:(i=r.split("").reverse().join("").search(/\d/),n=(a=r.length-i-1)+1):n+=1),b.val(r.substring(0,a)+r.substring(n,r.length)),u(a),!1))}function t(){v=b.val(),r();var e,t=b.get(0);t.createTextRange&&((e=t.createTextRange()).collapse(!1),e.select())}function o(){setTimeout(function(){r()},0)}function m(){return(parseFloat("0")/Math.pow(10,g.precision)).toFixed(g.precision).replace(new RegExp("\\.","g"),g.decimal)}function h(e){if(y.browser.msie&&i(e),""===b.val()||b.val()===c(m()))g.allowZero?g.affixesStay?b.val(c(m())):b.val(m()):b.val("");else if(!g.affixesStay){var t=b.val().replace(g.prefix,"").replace(g.suffix,"");b.val(t)}b.val()!==v&&b.change()}function p(){var e,t=b.get(0);t.setSelectionRange?(e=b.val().length,t.setSelectionRange(e,e)):b.val(b.val())}var v,b=y(this);g=y.extend(g,b.data()),b.unbind(".maskMoney"),b.bind("keypress.maskMoney",i),b.bind("keydown.maskMoney",e),b.bind("blur.maskMoney",h),b.bind("focus.maskMoney",t),b.bind("click.maskMoney",p),b.bind("cut.maskMoney",o),b.bind("paste.maskMoney",o),b.bind("mask.maskMoney",r)})}};y.fn.maskMoney=function(e){return t[e]?t[e].apply(this,Array.prototype.slice.call(arguments,1)):"object"!=typeof e&&e?void y.error("Method "+e+" does not exist on jQuery.maskMoney"):t.init.apply(this,arguments)}}(window.jQuery||window.Zepto),function(y){"use strict";y.browser||(y.browser={},y.browser.mozilla=/mozilla/.test(navigator.userAgent.toLowerCase())&&!/webkit/.test(navigator.userAgent.toLowerCase()),y.browser.webkit=/webkit/.test(navigator.userAgent.toLowerCase()),y.browser.opera=/opera/.test(navigator.userAgent.toLowerCase()),y.browser.msie=/msie/.test(navigator.userAgent.toLowerCase()));var t={destroy:function(){return y(this).unbind(".maskMoney"),y.browser.msie&&(this.onpaste=null),this},mask:function(a){return this.each(function(){var e,t=y(this);return"number"==typeof a&&(t.trigger("mask"),e=y(t.val().split(/\D/)).last()[0].length,a=a.toFixed(e),t.val(a)),t.trigger("mask")})},unmasked:function(){return this.map(function(){var a,e=y(this).val()||"0",t=-1!==e.indexOf("-");return y(e.split(/\D/).reverse()).each(function(e,t){return t?(a=t,!1):void 0}),e=(e=e.replace(/\D/g,"")).replace(new RegExp(a+"$"),"."+a),t&&(e="-"+e),parseFloat(e)})},init:function(g){return g=y.extend({prefix:"",suffix:"",affixesStay:!0,thousands:",",decimal:".",precision:2,allowZero:!1,allowNegative:!1},g),this.each(function(){function l(){var e,t,a,n,r,i=b.get(0),o=0,l=0;return"number"==typeof i.selectionStart&&"number"==typeof i.selectionEnd?(o=i.selectionStart,l=i.selectionEnd):(t=document.selection.createRange())&&t.parentElement()===i&&(n=i.value.length,e=i.value.replace(/\r\n/g,"\n"),(a=i.createTextRange()).moveToBookmark(t.getBookmark()),(r=i.createTextRange()).collapse(!1),-1<a.compareEndPoints("StartToEnd",r)?o=l=n:(o=-a.moveStart("character",-n),o+=e.slice(0,o).split("\n").length-1,-1<a.compareEndPoints("EndToEnd",r)?l=n:(l=-a.moveEnd("character",-n),l+=e.slice(0,l).split("\n").length-1))),{start:o,end:l}}function s(){var e=!(b.val().length>=b.attr("maxlength")&&0<=b.attr("maxlength")),t=l(),a=t.start,n=t.end,r=!(t.start===t.end||!b.val().substring(a,n).match(/\d/)),i="0"===b.val().substring(0,1);return e||r||i}function a(n){b.each(function(e,t){if(t.setSelectionRange)t.focus(),t.setSelectionRange(n,n);else if(t.createTextRange){var a=t.createTextRange();a.collapse(!0),a.moveEnd("character",n),a.moveStart("character",n),a.select()}})}function c(e){var t="";return-1<e.indexOf("-")&&(e=e.replace("-",""),t="-"),t+g.prefix+e+g.suffix}function n(e){var t,a,n,r=-1<e.indexOf("-")&&g.allowNegative?"-":"",i=e.replace(/[^0-9]/g,""),o=i.slice(0,i.length-g.precision);return""===(o=(o=o.replace(/^0*/g,"")).replace(/\B(?=(\d{3})+(?!\d))/g,g.thousands))&&(o="0"),t=r+o,0<g.precision&&(a=i.slice(i.length-g.precision),n=new Array(g.precision+1-a.length).join(0),t+=g.decimal+n+a),c(t)}function u(e){var t=b.val().length;b.val(n(b.val())),a(e-=t-b.val().length)}function r(){var e=b.val();b.val(n(e))}function d(){var e=b.val();return g.allowNegative?""!==e&&"-"===e.charAt(0)?e.replace("-",""):"-"+e:e}function f(e){e.preventDefault?e.preventDefault():e.returnValue=!1}function i(e){var t,a,n,r,i,o=(e=e||window.event).which||e.charCode||e.keyCode;return void 0!==o&&(o<48||57<o?45===o?(b.val(d()),!1):43===o?(b.val(b.val().replace("-","")),!1):(13===o||9===o||(!y.browser.mozilla||37!==o&&39!==o||0!==e.charCode)&&f(e),!0):(s()&&(f(e),t=String.fromCharCode(o),n=(a=l()).start,r=a.end,i=b.val(),b.val(i.substring(0,n)+t+i.substring(r,i.length)),u(n+1)),!1))}function e(e){var t,a,n,r,i,o=(e=e||window.event).which||e.charCode||e.keyCode;return void 0!==o&&(a=(t=l()).start,n=t.end,8!==o&&46!==o&&63272!==o||(f(e),r=b.val(),a===n&&(8===o?""===g.suffix?a-=1:(i=r.split("").reverse().join("").search(/\d/),n=(a=r.length-i-1)+1):n+=1),b.val(r.substring(0,a)+r.substring(n,r.length)),u(a),!1))}function t(){v=b.val(),r();var e,t=b.get(0);t.createTextRange&&((e=t.createTextRange()).collapse(!1),e.select())}function o(){setTimeout(function(){r()},0)}function m(){return(parseFloat("0")/Math.pow(10,g.precision)).toFixed(g.precision).replace(new RegExp("\\.","g"),g.decimal)}function h(e){if(y.browser.msie&&i(e),""===b.val()||b.val()===c(m()))g.allowZero?g.affixesStay?b.val(c(m())):b.val(m()):b.val("");else if(!g.affixesStay){var t=b.val().replace(g.prefix,"").replace(g.suffix,"");b.val(t)}b.val()!==v&&b.change()}function p(){var e,t=b.get(0);t.setSelectionRange?(e=b.val().length,t.setSelectionRange(e,e)):b.val(b.val())}var v,b=y(this);g=y.extend(g,b.data()),b.unbind(".maskMoney"),b.bind("keypress.maskMoney",i),b.bind("keydown.maskMoney",e),b.bind("blur.maskMoney",h),b.bind("focus.maskMoney",t),b.bind("click.maskMoney",p),b.bind("cut.maskMoney",o),b.bind("paste.maskMoney",o),b.bind("mask.maskMoney",r)})}};y.fn.maskMoney=function(e){return t[e]?t[e].apply(this,Array.prototype.slice.call(arguments,1)):"object"!=typeof e&&e?void y.error("Method "+e+" does not exist on jQuery.maskMoney"):t.init.apply(this,arguments)}}(window.jQuery||window.Zepto),function(){}.call(this),function(){}.call(this),function(){}.call(this),function(){}.call(this),function(){}.call(this),function(){}.call(this),function(){}.call(this),function(){}.call(this),function(){}.call(this),function(){}.call(this),function(){}.call(this),function(){}.call(this),function(){}.call(this),function(){}.call(this),function(){}.call(this),function(){}.call(this),function(){}.call(this),function(){jQuery(function(){var a;return a=$("#warehouse_city_name").html(),$("#warehouse_province_id").change(function(){var e,t;return t=$("#warehouse_province_id :selected").text(),(e=$(a).filter("optgroup[label='"+t+"']").html())?$("#warehouse_city_name").html(e):$("#warehouse_city_name").empty()})})}.call(this);