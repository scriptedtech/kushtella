class OrdersController < ApplicationController
	def destroy
	  current_order.destroy
	  session[:order_id] = nil
	  redirect_to root_path, :notice => "Basket emptied successfully."
	end

	def remove_item
   item = current_order.order_items.find(params[:id])
    if current_order.order_items.count == 1
      destroy
    else
      item.remove
      redirect_to basket_path, :notice => "Item has been removed from your basket successfully"
    end
  end

  def increase_item_quantity
  	item = current_order.order_items.find(params[:id])
  	amount = params[:amount].to_i
  	if amount > item.quantity && amount <= item.ordered_item.stock
  		if item.quantity == 1
  			amount = amount - 1
	  			amount.times do
						item.increase!
				end
				redirect_to basket_path, :notice => "Quantity has been updated successfully."
  		else
  			amount = amount - item.quantity
	  		amount.times do
					item.increase!
				end
				redirect_to basket_path, :notice => "Quantity has been updated successfully."
			end
		elsif amount > item.ordered_item.stock
			redirect_to basket_path, :alert => "Unfortunately, we don't have enough stock. We only have #{item.ordered_item.stock} items available at the moment. Please get in touch though, we're always receiving new stock."
		else
			item.increase!
			redirect_to basket_path, :notice => "Quantity has been updated successfully."
		end
  rescue Shoppe::Errors::NotEnoughStock => e
    redirect_to basket_path, :alert => "Unfortunately, we don't have enough stock. We only have #{item.ordered_item.stock} items available at the moment. Please get in touch though, we're always receiving new stock."
  end

  def decrease_item_quantity
    item = current_order.order_items.find(params[:id])
		item.decrease!
    redirect_to basket_path, :notice => "Quantity has been updated successfully."
  rescue Shoppe::Errors::NotEnoughStock => e
    redirect_to basket_path, :alert => "Unfortunately, we don't have enough stock. We only have #{item.ordered_item.stock} items available at the moment. Please get in touch though, we're always receiving new stock."
  end

  def bulk_update_quanity
  	bulk = params[:bulk]
  	item = current_order.order_items.find(params[:id])
  	if bulk.to_i > item.available_stock.to_i
	  	bulk.to_i.times do
	  		item.increase!
	  	end
  		redirect_to basket_path, :notice => "Quantity has been updated successfully."
  	end
  	rescue Shoppe::Errors::NotEnoughStock => e
    	redirect_to basket_path, :alert => "Unfortunately, we don't have enough stock. We only have #{item.ordered_item.stock} items available at the moment. Please get in touch though, we're always receiving new stock."
  end

	def checkout
  @order = Shoppe::Order.find(current_order.id)
	  if request.patch?
	    if @order.proceed_to_confirm(params[:order].permit(:first_name, :last_name, :billing_address1, :billing_address2, :billing_address3, :billing_address4, :billing_country_id, :billing_postcode, :email_address, :phone_number))
	      redirect_to checkout_payment_path
	    end
	  end
	end

	def show
	end

	def payment
	  @order = Shoppe::Order.find(current_order.id)
	  if request.post?
	    if @order.accept_stripe_token(params[:stripe_token])
	      redirect_to checkout_confirmation_path
	    else
	      flash.now[:notice] = "Could not exchange Stripe token. Please try again."
	    end
	  end
	end

	def confirmation
	  if request.post?
	    current_order.confirm!
	    session[:order_id] = nil
	    redirect_to root_path, :notice => "Order has been placed successfully!"
	  end
	end

end
