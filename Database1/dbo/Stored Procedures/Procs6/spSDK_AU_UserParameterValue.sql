CREATE procedure [dbo].[spSDK_AU_UserParameterValue]
@AppUserId int,
@HostName varchar(100) ,
@Parameter nvarchar(50) ,
@ParameterCategory varchar(100) ,
@ParameterCategoryId int ,
@ParameterId int ,
@ParameterType varchar(100) ,
@ParameterTypeId int ,
@ParmRequired bit ,
@UserId int ,
@Username nvarchar(30) ,
@Value varchar(4000) 
AS
 	 If (@ParameterId Is NULL) And (@Parameter Is NULL)
 	  	 Begin
 	  	  	 Select 'No Parameter Info Provided'
 	  	  	 return(-101)
 	  	 End
 	 If (@ParameterId Is NULL)
 	  	 Select @ParameterId = Parm_Id From Parameters Where Parm_Name = @Parameter
 	 If (@Parameter Is NULL)
 	  	 Select @Parameter = Parm_Name From Parameters Where Parm_Id = @ParameterId
 	 If (@ParameterId Is NULL) Or (@Parameter Is NULL)
 	  	 Begin
 	  	  	 Select 'Invalid Parameter Info'
 	  	  	 return(-102)
 	  	 End
 	  	 
 	 If (@UserId Is NULL) And (@UserName Is NULL)
 	  	 Begin
 	  	  	 Select 'No User Info Provided'
 	  	  	 return(-103)
 	  	 End
 	 If (@UserId Is NULL)
 	  	 Select @UserId = User_Id From Users Where Username = @UserName
 	 If (@Username Is NULL)
 	  	 Select @Username = Username From Users Where User_Id = @UserId
 	 If (@UserId Is NULL) Or (@UserName Is NULL)
 	  	 Begin
 	  	  	 Select 'Invalid User Info'
 	  	  	 return(-104)
 	  	 End
 	  	 
 	 If (@HostName Is NULL)
 	  	 Select @HostName = '' 	  	 
 	  	 
 	 IF EXISTS(SELECT 1 FROM User_Parameters Where (Parm_Id = @ParameterId) And (HostName = @HostName) And (User_Id = @UserId))
 	  	 Begin
 	  	  	 Update User_Parameters Set Value = @Value Where (Parm_Id = @ParameterId) And (HostName = @HostName) And (User_Id = @UserId)
 	  	 End
 	 Else
 	  	 Begin
 	  	  	 Insert Into User_Parameters (Parm_Id,HostName,Value,User_Id) Values(@ParameterId,@HostName,@Value,@UserId)
 	  	 End 	 
 	  	 
 	 Return(1)
 	 
