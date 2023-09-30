CREATE procedure [dbo].[spSDK_COMWrapperTest_Bak_177]
@Param1 int,
@Param2 int OUTPUT, -- treated as Input/Output for this test
@Param3 int OUTPUT
AS
 	 if (@Param1 <> 1)
 	  	 return(-1)
 	 if (@Param2 <> 2)
 	  	 return(-2)
 	 Select @Param2 = 200
 	 Select @Param3 = 3
 	 
 	 select Data_Type_Id,Data_Type_Desc from Data_Type where Data_Type_Id < 3
 	 select Data_Type_Id,Data_Type_Desc from Data_Type where Data_Type_Id < 3
 	 
 	 return(100)
