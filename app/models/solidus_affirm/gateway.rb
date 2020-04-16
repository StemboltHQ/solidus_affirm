module SolidusAffirm
  class Gateway < SolidusSupport.payment_method_parent_class
    preference :public_api_key, :string
    preference :private_api_key, :string
    preference :javascript_url, :string

    def gateway_class
      AffirmClient
    end
    alias_method :provider_class, :gateway_class

    def payment_source_class
      SolidusAffirm::Checkout
    end

    def source_required?
      true
    end

    def partial_name
      'affirm'
    end
    alias_method :method_type, :partial_name

    def supports?(source)
      source.is_a? payment_source_class
    end

    def payment_profiles_supported?
      false
    end

    # Affirm doesn't have a purcase endpoint
    # so autocapture doesn't make sense. Especially because you have to
    # leave the store and come back to confirm your order. Stores should
    # capture affirm payments after the order transitions to complete.
    # @return false
    def auto_capture
      false
    end

    # Will either refund or void the payment depending on its state.
    #
    # If the transaction has not yet been captured, we can void the transaction.
    # Otherwise, we need to issue a refund.
    def cancel(charge_id, try_credit = true)
      initialize_gateway

      begin
        transaction = ::Affirm::Client.new.read_transaction(charge_id)
        # workaround: on 404 responses we get XML data from the API.
        # the affirm-ruby gem doesn't handle non-JSON responses at the moment.
      rescue Exception => e
        return ActiveMerchant::Billing::Response.new(false, e.message)
      end

      if voidable?(transaction)
        void(charge_id, nil, {})
      else
        try_credit ? credit(nil, charge_id, {}) : false
      end
    end

    def try_void(payment)
      cancel(payment.response_code, false)
    end

    private

    def voidable?(transaction)
      transaction.status == "authorized"
    end

    def initialize_gateway
      # We can just leave gateway after Solidus 2.2 EOL
      return gateway if respond_to?(:gateway)

      provider
    end
  end
end
