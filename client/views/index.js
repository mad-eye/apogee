Template.topnav.rendered = function(){
  if("home" == Meteor.Router._page || "home2" == Meteor.Router._page || "getStarted" == Meteor.Router._page){
    !function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0];if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src="//platform.twitter.com/widgets.js";fjs.parentNode.insertBefore(js,fjs);}}(document,"script","twitter-wjs");
  }
};
