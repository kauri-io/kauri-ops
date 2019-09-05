var disposableService = "dispostable.com";

db.user.find().forEach(function(user){

  if(user.email) {
    var email = user.email;
    var exp = new RegExp('(.+)@(.+)', 'gm');
    var newEmail = email.replace(exp, '$1_at_$2@'+disposableService);

    db.user.update({"_id": user._id}, {$set:{"email": newEmail}});
  }
});
