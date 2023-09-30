CREATE procedure [dbo].[spSDK_AU_DataType]
@AppUserId int,
@Id int OUTPUT,
@DataType nvarchar(50) ,
@IsUserDefined bit 
AS
 	 If (@DataType Is NULL) Or (@DataType = '')
 	  	 Begin
 	  	  	 Select 'Must provide DataType'
 	  	  	 return(0)
 	  	 End
 	 If (@Id Is NULL)
 	  	 Select @Id = Data_Type_Id From Data_Type Where Data_Type_Desc = @DataType
 	  	 
 	 -- Add
 	 If (@Id Is NULL)
 	  	 Begin
 	  	  	 Insert Into Data_Type(Data_Type_Desc,User_Defined) Values(@DataType,1)
 	  	  	 Select @Id = Data_Type_Id From Data_Type Where Data_Type_Desc = @DataType
 	  	  	 return(1)
 	  	 End
 	  	 
 	 -- Update
 	 If (@Id <= 50)
 	  	 Begin
 	  	  	 Select 'System datatypes are not Updatable'
 	  	  	 Return(0)
 	  	 End
 	  	 
 	 Update Data_Type Set Data_Type_Desc = @DataType Where Data_Type_Id = @Id
 	 return(1)
 	 
