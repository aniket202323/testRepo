CREATE PROCEDURE dbo.spEM_STGetSubscriptionData
 	 @SubscriptionId 	  	  	 Int
  AS
 	  	 
 	 Select st.Subscription_Trigger_Id,st.Table_Id,
 	  	  	 keytext = Case When Table_Id = 1 then '<' + Convert(nVarChar(10),st.Key_Id) + '> ' + (Select  PU_Desc From Prod_Units where PU_Id = Key_Id)
 	  	  	  	  	  	  	  	  	  	  When Table_Id = 7 then '<' + Convert(nVarChar(10),st.Key_Id) + '> ' + (Select  Path_Desc From PrdExec_Paths where Path_Id = Key_Id)
 	  	  	  	  	  	  	  	 End, 
 	  	  	 st.Column_Name,st.From_Value,st.To_Value
 	  	  	 From Subscription_Trigger st
 	  	  	 where st.Subscription_Id = @SubscriptionId
 	 Select Last_Processed_Date
 	  	 From Subscription
 	  	 Where Subscription_Id = @SubscriptionId
 	 Select [Tag] =  Char(1) + '1' + Char(1) +  Convert(nVarChar(10),tfv.Table_Field_Id) + Char(2) + Char(1) + '2' + Char(1) + + Convert(nVarChar(10),tf.ED_Field_Type_Id) + Char(2) + Char(1) + '3' + Char(1) +  + eft.Field_Type_Desc + Char(2),[User Defined Field] = tf.Table_Field_Desc,tfv.Value
 	  	 From Table_Fields_Values tfv
 	  	 Join Table_Fields tf On tfv.Table_Field_Id = tf.Table_Field_Id
 	  	 Join Ed_Fieldtypes eft On eft.ED_Field_Type_Id = tf.ED_Field_Type_Id
 	 Where tfv.TableId = 27 and KeyId = @SubscriptionId
 	 Order by tf.Table_Field_Desc
