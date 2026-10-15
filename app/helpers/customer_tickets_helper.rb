# Musterinin gordugu durum adlari. Temsilcinin dilinden farkli: "Musteri bekleniyor" musteriye "Yanitiniz bekleniyor" olur.
module CustomerTicketsHelper
  CUSTOMER_STATUS_LABELS = {
    "new" => "Alındı",
    "open" => "İnceleniyor",
    "pending" => "Yanıtınız bekleniyor",
    "on_hold" => "İnceleniyor",
    "solved" => "Çözüldü",
    "closed" => "Kapandı"
  }.freeze

  def customer_status_chip(status)
    tag.span(CUSTOMER_STATUS_LABELS.fetch(status.to_s, status.to_s), class: "chip chip-status-#{status}")
  end

  # Musteriye talebin su an neyi bekledigini tek cumleyle anlatir.
  def customer_status_note(ticket)
    case ticket.status
    when "new", "open"
      if ticket.first_responded_at.nil? && ticket.first_response_due_at
        "Talebiniz ekibimizde. İlk yanıtımızı en geç #{tr_time(ticket.first_response_due_at)} tarihine kadar vereceğiz."
      else
        "Talebiniz ekibimizde, üzerinde çalışıyoruz."
      end
    when "pending"
      note = "Sizden bir yanıt bekliyoruz."
      note += " #{tr_time(ticket.auto_solve_at)} tarihine kadar yanıt gelmezse talep çözüldü sayılır." if ticket.auto_solve_at
      note
    when "on_hold"
      "Bir dış birimden (ör. kargo, banka, tedarikçi) yanıt bekliyoruz. Bu sırada yanıt süreniz işlemez."
    when "solved"
      note = "Talebiniz çözüldü. Sorun devam ediyorsa aşağıdan yazın; talep yeniden açılır."
      note += " Yazmazsanız #{tr_time(ticket.auto_close_at)} tarihinde kapanır." if ticket.auto_close_at
      note
    when "closed"
      "Bu talep kapandı. Yeni bir sorun için yeni talep açabilirsiniz."
    end
  end
end
