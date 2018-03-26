require 'transaction'
class FinancialSummary < ApplicationRecord
  @summary_totals = {}
  belongs_to :user

  def self.count(category)
    @summary_totals[category][:count]
  end

  def self.amount(category)
    cents = @summary_totals[category][:amount]
    Money.us_dollar(cents)
  end

  def self.one_day(user:, currency:)
    @summary_totals = self.categorized_totals(user: user, currency:currency, days_ago: 1)
    return self
  end

  def self.seven_days(user:, currency:)
    @summary_totals = self.categorized_totals(user: user, currency:currency, days_ago: 7)
    return self
  end

  def self.lifetime(user:, currency:)
    @summary_totals = self.categorized_totals(user: user, currency:currency, days_ago: 0)
    return self
  end

  private
  def self.categorized_totals(user:, currency:, days_ago: )
    d = self.user_transactions(user: user, currency: currency, category: "deposit", days_ago: days_ago)
    w = self.user_transactions(user: user, currency: currency, category: "withdraw", days_ago: days_ago)
    r = self.user_transactions(user: user, currency: currency, category: "refund", days_ago: days_ago)
    return {:deposit => {:amount => self.transaction_sum(d), :count => d.count},
            :withdraw => {:amount => self.transaction_sum(w), :count => w.count},
            :refund => {:amount => self.transaction_sum(r),  :count => r.count} }
  end

  def self.user_transactions(user:, category:, currency:, days_ago:)
    if(days_ago > 0)
      Transaction.where(user_id: user.id, amount_currency: currency.to_s.upcase, category: category).where("created_at > ?", Time.now - days_ago.day)
    else
      Transaction.where(user_id: user.id, amount_currency: currency.to_s.upcase, category: category)
    end
  end

  def self.transaction_sum(txns)
    txns.map do |t| t[:amount_cents] end.reduce(0, :+)
  end
end