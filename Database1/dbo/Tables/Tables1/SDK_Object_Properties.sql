﻿CREATE TABLE [dbo].[SDK_Object_Properties] (
    [ObjectPropertyId]           INT           IDENTITY (1, 1) NOT NULL,
    [ObjectId]                   INT           NULL,
    [SDKVersion]                 VARCHAR (100) NOT NULL,
    [PropertyName]               VARCHAR (100) NULL,
    [LinkedPropertyName]         VARCHAR (100) NULL,
    [StringToIdLookupObjectId]   INT           NULL,
    [StingToIdEvaluationOrder]   INT           NULL,
    [DefaultValue]               VARCHAR (500) NULL,
    [QueryLocationName]          VARCHAR (255) NULL,
    [SqlDataTypeName]            VARCHAR (100) NULL,
    [NLSPromptId]                INT           NULL,
    [IsKey]                      BIT           NULL,
    [IsExtraLookupProperty]      BIT           NULL,
    [IsCustomLookupProperty]     BIT           NULL,
    [IsAddable]                  BIT           NULL,
    [IsUpdatable]                BIT           NULL,
    [ForceDefaultOnInsertUpdate] BIT           NULL,
    [DefaultIsSelectedForQuery]  BIT           NULL,
    [DefaultOrderByForQuery]     INT           NULL,
    [PropertyDescription]        VARCHAR (500) NULL,
    [Calculation]                VARCHAR (500) NULL,
    [IsWDDBParam]                BIT           NULL,
    [IsReqWDDBParam]             BIT           NULL,
    [WDParamDirection]           VARCHAR (20)  NULL,
    [WDSPParamName]              VARCHAR (50)  NULL,
    [AccessLevelItemNum]         INT           NULL,
    [IsDEIParam]                 BIT           NULL,
    [DEIParamName]               VARCHAR (50)  NULL,
    [DEIChangeParamName]         VARCHAR (50)  NULL,
    [IsESigInfoParam]            BIT           NULL,
    [ESigInfoParamName]          VARCHAR (50)  NULL,
    [IsESigProperty]             BIT           NULL,
    CONSTRAINT [SDK_Objects_PK_ObjectPropertyId] PRIMARY KEY CLUSTERED ([ObjectPropertyId] ASC),
    CONSTRAINT [SDK_Object_Properties_FK_ObjectId] FOREIGN KEY ([ObjectId]) REFERENCES [dbo].[SDK_Objects] ([ObjectId])
);
