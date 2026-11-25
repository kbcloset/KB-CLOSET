-- KB Closet: salvar forma de pagamento nos pedidos
-- Execute no Supabase: SQL Editor > New query > Run

ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS payment_method text;

CREATE OR REPLACE FUNCTION public.set_order_payment_method(
  p_order_id uuid,
  p_payment_method text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_zone text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Você precisa entrar na sua conta.';
  END IF;

  IF p_payment_method NOT IN ('pix', 'card_delivery', 'card_link') THEN
    RAISE EXCEPTION 'Forma de pagamento inválida.';
  END IF;

  SELECT delivery_zone
    INTO v_zone
    FROM public.orders
   WHERE id = p_order_id
     AND user_id = auth.uid();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pedido não encontrado para esta conta.';
  END IF;

  IF p_payment_method = 'card_delivery' AND v_zone = 'Outro' THEN
    RAISE EXCEPTION 'Para essa região, cartão somente por link da Ton.';
  END IF;

  UPDATE public.orders
     SET payment_method = p_payment_method
   WHERE id = p_order_id
     AND user_id = auth.uid();
END;
$$;

REVOKE ALL ON FUNCTION public.set_order_payment_method(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.set_order_payment_method(uuid, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.set_order_payment_method(uuid, text) TO authenticated;
