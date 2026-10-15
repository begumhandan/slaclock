module TicketsHelper
  STATUS_LABELS = {
    "new" => "Yeni",
    "open" => "Açık",
    "pending" => "Müşteri bekleniyor",
    "on_hold" => "Beklemede (3. taraf)",
    "solved" => "Çözüldü",
    "closed" => "Kapandı"
  }.freeze

  PRIORITY_LABELS = {
    "low" => "Düşük",
    "normal" => "Normal",
    "high" => "Yüksek",
    "urgent" => "Acil"
  }.freeze

  def status_label(status) = STATUS_LABELS.fetch(status.to_s, status.to_s)
  def priority_label(priority) = PRIORITY_LABELS.fetch(priority.to_s, priority.to_s)
end
