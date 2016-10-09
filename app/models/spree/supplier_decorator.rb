Spree::Supplier.class_eval do

  attr_accessor :first_name, :last_name, :merchant_type

  has_many :bank_accounts, class_name: 'Spree::SupplierBankAccount'

  validates :tax_id, length: { is: 9, allow_blank: true }

  before_create :assign_name
  before_create :stripe_account_setup
  before_save :stripe_account_update

  private

  def assign_name
    self.address = Spree::Address.default     unless self.address.present?
    self.address.first_name = self.first_name unless self.address.first_name.present?
    self.address.last_name = self.last_name   unless self.address.last_name.present?
  end

  def stripe_account_setup
    return if self.tax_id.blank? and self.address.blank?

    account = Stripe::Account.create(
      :country => "US",
      :managed => true,
      :email => self.email,
      :bank_account => self.bank_accounts.first.try(:token)
    )

    if new_record?
      self.token = account.id
    else
      self.update_column :token, account.id
    end
  end

  def stripe_account_update
    puts "update\n\n\n\n\n\n\n\n"
    unless new_record?
      puts token.present?
      if token.present?
        rp = Stripe::Account.retrieve(token)
        rp.business_name = name
        rp.email = email
        if tax_id.present?
          rp.tax_id = tax_id
        end
        account = bank_accounts.first
        puts "dankkkkkkk================================================"
        puts account
        puts "dankkkkkkk================================================"
        unless account.nil?
          rp.external_account = {
            :object => "bank_account",
            :account_number => account.account_number,
            :routing_number => account.routing_number,
            :curreny => "USD",
            :country => "US",
          }
        end
        rp.save
      else
        stripe_account_setup
      end
    end
  end

end
