CREATE TABLE [dbo].[Dashboard_Template_Parameters] (
    [Dashboard_Template_Parameter_ID]    INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [allow_nulls]                        INT           CONSTRAINT [DashboardTemplateParameters_DF_AllowNulls] DEFAULT ((0)) NULL,
    [Dashboard_Parameter_Type_ID]        INT           NOT NULL,
    [Dashboard_Template_ID]              INT           NOT NULL,
    [Dashboard_Template_Parameter_Name]  VARCHAR (100) NOT NULL,
    [Dashboard_Template_Parameter_Order] INT           NOT NULL,
    [Has_Default_Value]                  BIT           NOT NULL,
    CONSTRAINT [PK_Dashboard_Template_Parameters] PRIMARY KEY NONCLUSTERED ([Dashboard_Template_Parameter_ID] ASC, [Dashboard_Template_ID] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_Dashboard_Template_Parameters]
    ON [dbo].[Dashboard_Template_Parameters]([Dashboard_Template_Parameter_ID] ASC);

