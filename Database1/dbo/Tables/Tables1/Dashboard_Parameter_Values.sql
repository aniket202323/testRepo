CREATE TABLE [dbo].[Dashboard_Parameter_Values] (
    [Dashboard_Parameter_Value_ID]    INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Parameter_Column]      INT            NOT NULL,
    [Dashboard_Parameter_Row]         INT            NOT NULL,
    [Dashboard_Parameter_Value]       VARCHAR (4000) NOT NULL,
    [Dashboard_Report_ID]             INT            NOT NULL,
    [Dashboard_Template_Parameter_ID] INT            NOT NULL,
    CONSTRAINT [PK_Dashboard_Parameter_Values] PRIMARY KEY NONCLUSTERED ([Dashboard_Parameter_Value_ID] ASC, [Dashboard_Report_ID] ASC, [Dashboard_Template_Parameter_ID] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_Dashboard_Parameter_Values]
    ON [dbo].[Dashboard_Parameter_Values]([Dashboard_Parameter_Value_ID] ASC);

