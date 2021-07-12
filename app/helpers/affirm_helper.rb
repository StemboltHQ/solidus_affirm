module AffirmHelper
  def affirm_js_setup(public_api_key, javascript_url)
    output = %(
      var _affirm_config = {
        public_api_key: "#{public_api_key}",
        script: "#{javascript_url}"
      };
      (function(l,g,m,e,a,f,b){var d,c=l[m]||{},h=document.createElement(f),n=document.getElementsByTagName(f)[0],k=function(a,b,c){return function(){a[b]._.push([c,arguments])}};c[e]=k(c,e,"set");d=c[e];c[a]={};c[a]._=[];d._=[];c[a][b]=k(c,a,b);a=0;for(b="set add save post open empty reset on off trigger ready setProduct".split(" ");a<b.length;a++)d[b[a]]=k(c,e,b[a]);a=0;for(b=["get","token","url","items"];a<b.length;a++)d[b[a]]=function(){};h.async=!0;h.src=g[f];n.parentNode.insertBefore(h,n);delete g[f];d(g);l[m]=c})(window,_affirm_config,"affirm","checkout","ui","script","ready");
    )
    javascript_tag output
  end

  def affirm_payload_json(order, payment_method, metadata = {})
    config = {
      confirmation_url: spree.confirm_affirm_url(payment_method_id: payment_method.id, order_id: order.id),
      cancel_url: spree.cancel_affirm_url(payment_method_id: payment_method.id, order_id: order.id)
    }

    order.payments.where(source_type: 'SolidusAffirm::Checkout').pending.collect(&:cancel!)

    payload = SolidusAffirm::CheckoutPayload.new(order, config, metadata)
    SolidusAffirm::Config.checkout_payload_serializer.new(payload, root: false).to_json
  end
end
