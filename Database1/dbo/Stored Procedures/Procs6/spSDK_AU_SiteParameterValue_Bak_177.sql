CREATE procedure [dbo].[spSDK_AU_SiteParameterValue_Bak_177]
@AppUserId int,
@HostName varchar(100) ,
@Parameter nvarchar(50) ,
@ParameterCategory varchar(100) ,
@ParameterCategoryId int ,
@ParameterId int ,
@ParameterType varchar(100) ,
@ParameterTypeId int ,
@ParmRequired bit ,
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
 	  	 
 	 If (@HostName Is NULL)
 	  	 Select @HostName = '' 	  	 
 	  	 
 	 IF EXISTS(SELECT 1 FROM Site_Parameters Where (Parm_Id = @ParameterId) And (HostName = @HostName))
 	  	 Begin
 	  	  	 Update Site_Parameters Set Value = @Value Where (Parm_Id = @ParameterId) And (HostName = @HostName)
 	  	 End
 	 Else
 	  	 Begin
 	  	  	 Insert Into Site_Parameters (Parm_Id,HostName,Value) Values(@ParameterId,@HostName,@Value)
 	  	 End 	 
 	  	 
 	 Return(1)
 	 
