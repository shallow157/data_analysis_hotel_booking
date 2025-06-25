# 酒店预订取消率分析项目（Hotel Booking Cancellation Analysis）

## 项目简介  
本项目基于 Kaggle `hotel_bookings` 数据集，深入分析酒店预订业务特征，探究 City Hotel 取消率显著高于 Resort Hotel 的原因，并通过 **预测模型（Python）、量化模拟（SQL）、可视化策略沙盘（PowerBI/Tableau）** 提出优化方案，助力酒店降低取消率、提升收益。  


## 核心目标  
1. 剖析酒店预订取消率的关键影响因素（如押金政策、渠道、提前期等）。  
2. 构建精准预测模型（XGBoost）识别高取消风险订单。  
3. 通过 SQL 量化模拟验证策略效果，用 PowerBI/Tableau 可视化呈现业务洞察。  



## 文件夹结构说明  
Hotel_Booking_Analysis/

├── data/ # 数据文件（原始 + 处理后）

├── notebooks/ # 分析流程 Notebook（预处理→建模→解释）

├── sql/ # SQL 量化模拟脚本（策略验证、数据预处理）

├── powerbi/ # PowerBI 策略沙盘报表

├── tableau/ # Tableau 可视化成果

├── models/ # 训练好的预测模型（如 XGBoost）

├── reports/ # 分析报告（详细版 + 精简版）

├── docs/ # 补充文档（数据字典、整体思路）

└── README.md # 项目说明（你正在阅读的内容）



## 关键流程与成果  
### 1. 数据预处理（`notebooks/0_data_preprocessing.ipynb`）  
- 处理缺失值（如 `company` `agent` 字段）、异常值（如极端房价 `adr`）。  
- 修复日期逻辑（确保预订日期早于入住日期），为分析奠定基础。  

### 2. 探索性分析（`notebooks/1_exploratory_analysis.ipynb`）  
- 揭示核心业务指标：City Hotel 取消率（42.37%）显著高于 Resort Hotel（29.86%）。  
- 分析关键影响因素：**押金政策、渠道组合、提前期、客户类型** 对取消率的影响。  

### 3. 预测模型构建与调优（`notebooks/2_model_building.ipynb` & `3_hyperparameter_tuning.ipynb`）  
- 模型：XGBoost（解决类别不平衡问题，`scale_pos_weight=1.4`）。  
- 调优：通过 GridSearchCV 优化超参数（最佳参数：`max_depth=7, learning_rate=0.1` 等），验证集 AUC 达 **0.8919**，测试集 AUC **0.9069**。  

### 4. 模型解释与业务洞察（`notebooks/4_shap_analysis.ipynb`）  
- 用 SHAP 分析特征影响：`lead_time`（提前期）、`deposit_type`（押金类型）是取消率核心驱动因素。  
- 个体订单解释：揭示高风险订单的特征组合（如长提前期+历史取消记录）。  

### 5. 策略验证与可视化（`sql/` & `powerbi/` & `tableau/`）  
- SQL 量化模拟：验证押金政策、渠道优化对取消率的影响。  
- PowerBI/Tableau 可视化：通过交互报表展示策略效果（如调整押金政策后取消率变化）
