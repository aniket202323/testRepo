 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-04  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_GetProfleAVG  
Author:   Fran Osorno  
Date Created:  03/03/2004  
  
Description:  
=========  
Gets the standard Deviation of 12 inputs passed to it by a calculation variable.  
  
Change Date Who What  
=========== ==== =====  
  
*/  
  
CREATE PROCEDURE dbo.spLocal_GetProfileAVG  
@OutputValue varchar(25) OUTPUT,  
@A  float(24),  
@B  float(24),  
@C  float(24),  
@D  float(24),  
@E  float(24),  
@F  float(24),  
@G  float(24),  
@H  float(24),  
@I  float(24),  
@J  float(24),  
@K  float(24),  
@L  float(24),  
@M  float(24),  
@N  float(24),  
@O  float(24),  
@P  float(24),  
@Q  float(24),  
@R  float(24),  
@S  float(24),  
@T  float(24),  
@U  float(24)  
  
AS  
  
SET NOCOUNT OFF  
  
Declare  
 @Total   float(24),  
 @Count  int  
  
--  /* Enter inputs into temporary table called '@Table' */  
-- if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[@Table]'))  
--  drop table [dbo].[@Table]  
--   
-- CREATE TABLE @Table(tests Float)  
DECLARE @Table TABLE (tests Float)  
INSERT INTO @Table Values(@A)  
INSERT INTO @Table Values(@B)  
INSERT INTO @Table Values(@C)  
INSERT INTO @Table Values(@D)  
INSERT INTO @Table Values(@E)  
INSERT INTO @Table Values(@F)  
INSERT INTO @Table Values(@G)  
INSERT INTO @Table Values(@H)  
INSERT INTO @Table Values(@I)  
INSERT INTO @Table Values(@J)  
INSERT INTO @Table Values(@K)  
INSERT INTO @Table Values(@L)  
INSERT INTO @Table Values(@M)  
INSERT INTO @Table Values(@N)  
INSERT INTO @Table Values(@O)  
INSERT INTO @Table Values(@P)  
INSERT INTO @Table Values(@Q)  
INSERT INTO @Table Values(@R)  
INSERT INTO @Table Values(@S)  
INSERT INTO @Table Values(@T)  
INSERT INTO @Table Values(@U)  
  
 /* Get Standard Deviation */  
select @Count = count(tests)From @Table  
  where tests>0  
select @Total = sum(tests)From @Table  
IF @Count > 0   
 Select @Outputvalue = @Total/@Count  
  
SET NOCOUNT OFF  
  
