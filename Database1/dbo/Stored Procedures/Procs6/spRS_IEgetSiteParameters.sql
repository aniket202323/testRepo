CREATE PROCEDURE dbo.spRS_IEgetSiteParameters
 	 @Parm_Id int = Null
AS
/*  For use in Import/Export report packages
    MSI-MT 8-10-2000
*/
If @Parm_Id Is Null
    BEGIN Select SPARM.* From Site_Parameters SPARM
    END
Else
    BEGIN Select SPARM.* From Site_Parameters SPARM Where SPARM.Parm_Id = @Parm_Id
    END
