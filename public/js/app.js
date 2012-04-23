$(function() {
  $status_box = $("#status_box");
  // TODO make css backgrounds and remove all this!
  $(".machine").each(function() {
    $(this).append("<img src=\"img/machine.png\" width=\"100%\" height=\"40\" alt=\"" + $(this)[0].id + "\" />")
  });
  $(".up.machine").each(function() {
    $(this).find("img").replaceWith("<img src=\"img/flipped-machine.png\" width=\"40\" alt=\"" + $(this)[0].id + "\" />");
  });
  $("table").bind("mousemove", function(e) {
    $target = $(e.target);
    if ($target.attr("src") !== undefined) {
      $target = $target.parent();
    }
    $name = $target[0].id;
    $(".hovered").removeClass("hovered");
    if ($target.hasClass("machine") && $name != "") {
      $status_box.html("<p>" + $target[0].id + "</p><p>" + $target.find(".uptime").html() + "</p>");
      $status_box.css({
        "top": e.pageY + 10,
        "left": e.pageX + 10
      }).show();
      $target.addClass("hovered");
    } else {
      $status_box.hide();
    }
  });
});
