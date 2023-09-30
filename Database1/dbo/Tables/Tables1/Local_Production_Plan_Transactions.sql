CREATE TABLE [dbo].[Local_Production_Plan_Transactions] (
    [PP_Changes_Id]              INT           IDENTITY (1, 1) NOT NULL,
    [Transaction_Type]           CHAR (1)      NULL,
    [Process_Order]              VARCHAR (50)  NULL,
    [Path_Code]                  VARCHAR (50)  NULL,
    [Forecast_Start_Date]        DATETIME      NULL,
    [Forecast_End_Date]          DATETIME      NULL,
    [BOM_Formulation_Desc]       VARCHAR (50)  NULL,
    [Product_Production_Rule_Id] VARCHAR (50)  NULL,
    [Pattern_Code]               VARCHAR (25)  NULL,
    [Forecast_Quantity]          FLOAT (53)    NULL,
    [PPS_PP_Status_Desc]         VARCHAR (50)  NULL,
    [PP_PP_Status_Desc]          VARCHAR (50)  NULL,
    [Source_Trigger]             VARCHAR (255) NULL,
    [Transaction_TimeStamp]      DATETIME      NULL,
    [Processed_TimeStamp]        DATETIME      NULL,
    [Error_Code]                 INT           NULL,
    [Message]                    VARCHAR (255) NULL,
    [Product_Code]               VARCHAR (50)  NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [PK_PP_Changes_Id]
    ON [dbo].[Local_Production_Plan_Transactions]([PP_Changes_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_Source_PP_Trans_Pattern_Code]
    ON [dbo].[Local_Production_Plan_Transactions]([Pattern_Code] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_Source_PP_Trans_Path]
    ON [dbo].[Local_Production_Plan_Transactions]([Source_Trigger] ASC, [PP_PP_Status_Desc] ASC, [Transaction_Type] ASC, [Path_Code] ASC, [Processed_TimeStamp] ASC);

