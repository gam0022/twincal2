$(function(){
  $("form").submit(function(){
    //エラーの初期化
    $("p.alert-error").remove();
    $(".validate").each(function(){
      //必須項目のチェック
      $(this).filter(".required").each(function(){
        if($(this).val()==""){
        $(this).parent().prepend('<p class="alert alert-error"><a class="close" data-dismiss="alert" href="#">×</a>  選択してください。</p>')
        }
      })
    })
    //エラーの際の処理
    if($("p.alert-error").size() > 0){
      $('html,body').animate({scrollTop: ($("p.alert-error:first").offset().top-100) }, 'slow');
      return false;
    }
  }) 
})
