CREATE PROCEDURE dbo.spEM_CreateUniqueTransDesc 
  @Trans_Desc      nvarchar(50) Output
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Transaction name exists
  --
Declare @BaseDesc nvarchar(50),@RepeatCode VarChar(4),@Id Int,@NewDesc nvarchar(50),@Start Int,@Version Int
Select @Trans_Desc = Replace(@Trans_Desc,'<New>','')
Select @NewDesc = '<New>' + @Trans_Desc
If substring(@NewDesc,len(@NewDesc)-3,1) = ':' and isnumeric(right(@NewDesc,3)) = 1
 	 Begin
 	   Select @BaseDesc = Left(@Trans_Desc,len(@Trans_Desc)-4)
 	  	 Select @Version = Convert(Int,right(@NewDesc,3))
 	 End
Select @BaseDesc = isnull(@BaseDesc,@Trans_Desc)
Select @Id = 1,@Version = Isnull(@Version,0)
While @Id is Not Null
  Begin
 	  	 Select @Id = Null
 	  	 Select @Id = Trans_Id from Transactions WHERE Trans_Desc = @Trans_Desc or Trans_Desc = @NewDesc
 	  	 If @Id Is not Null
 	  	  	 Begin
 	  	  	  	 Select @Version = @Version + 1
 	  	  	  	 If @Version < 10
 	  	  	  	  	 Select @RepeatCode = ':00' + Convert(nVarChar(1),@Version)
 	  	  	  	 Else
 	  	  	  	 If @Version < 100
 	  	  	  	  	 Select @RepeatCode = ':0' + Convert(nVarChar(2),@Version)
 	  	  	  	 Else
 	  	  	  	  	 Select @RepeatCode = ':' + Convert(nVarChar(3),@Version)
 	  	  	  	 Select @Trans_Desc = @BaseDesc + @RepeatCode
 	  	  	  	 Select @NewDesc = '<New>' + @Trans_Desc
 	  	  	 End
 	 End
