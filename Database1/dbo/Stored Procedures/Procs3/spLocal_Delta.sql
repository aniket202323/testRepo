
--drop proc spLocal_Delta
CREATE PROCEDURE [dbo].[spLocal_Delta]

/*-----------------------------------------------------------------------------------------------
Stored Procedure:		dbo.spLocal_Delta
Author:   				Rakendra Lodhi)
Date Created:  		18-Oct-2016
SP Type:					Calculation
Editor Tab Spacing:	3

Description:
=========
	*/


	(

	@OutputMessage				INT OUTPUT,
	@Timestamp					DATETIME,
    @Tvaridvalue varchar(100),
	@Varid1						INT,
	@Varid2					INT
	
							

	)

As
SET NOCOUNT ON

DECLARE @VarsToUpdate1 TABLE(
	Var_Id	INT,
	entry_on	Datetime,
	Result_on Datetime )	
DECLARE @VarsToUpdate2 TABLE(
	Var_Id	INT,
	entry_on	Datetime,
	Result_on Datetime)	
insert  @VarsToUpdate1(var_id,entry_on,Result_on)
select  Var_Id,Entry_On,Result_On from tests where Var_Id=@Varid1 and Result_On=@Timestamp
insert  @VarsToUpdate2(var_id,entry_on,Result_on)
select  Var_Id,Entry_On,Result_On from tests where Var_Id=@Varid2 and Result_On=@Timestamp


SET @OutputMessage=(select DATEDIFF(second,t1.entry_on,t2.entry_on) from @VarsToUpdate1 t1 
join @VarsToUpdate2 t2 on t1.Result_on=t2.Result_on )

--SET @OutputMessage = @OutputMessage + 1 

SET NOCOUNT OFF


