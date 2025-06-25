import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

## read the data
df = pd.read_csv('hotel_bookings_processed.csv')
plt.rcParams['font.sans-serif'] = ['SimHei']

## 1. 整体业务概览
print("=== 基础业务指标 ===")
print(f"总订单数: {len(df)}")
print(f"整体取消率: {df['is_canceled'].mean():.2%}")
print(f"平均提前期: {df['lead_time'].mean():.1f}天")
print(f"平均每日房价: €{df['adr'].mean():.2f}")

# 按酒店类型分组统计
hotel_stats = df.groupby('hotel').agg(
    total_bookings=('is_canceled', 'count'),
    cancel_rate=('is_canceled', 'mean'),
    avg_lead_time=('lead_time', 'mean'),
    avg_adr=('adr', 'mean')
).reset_index()
print("\n按酒店类型统计:")
print(hotel_stats)


# 2. 客户行为分析
plt.figure(figsize=(12, 6))
sns.countplot(data=df, x='customer_type', hue='is_canceled')
plt.title('不同客户类型的取消情况')
plt.ylabel('订单数量')
plt.xticks(rotation=45)
plt.legend(title='是否取消', labels=['未取消', '已取消'])
plt.show()

# 3. 季节性模式分析
# 创建月份数字映射
month_map = {'January':1, 'February':2, 'March':3, 'April':4, 'May':5, 'June':6,
             'July':7, 'August':8, 'September':9, 'October':10, 'November':11, 'December':12}
df['arrival_month_num'] = df['arrival_date_month'].map(month_map)

# 按月份分析预订量和取消率
monthly_data = df.groupby('arrival_month_num').agg(
    total_bookings=('is_canceled', 'count'),
    cancel_rate=('is_canceled', 'mean')
).reset_index()

plt.figure(figsize=(14, 6))
plt.subplot(1, 2, 1)
sns.lineplot(data=monthly_data, x='arrival_month_num', y='total_bookings')
plt.title('月度预订量趋势')
plt.xlabel('月份')
plt.ylabel('预订量')

plt.subplot(1, 2, 2)
sns.lineplot(data=monthly_data, x='arrival_month_num', y='cancel_rate')
plt.title('月度取消率趋势')
plt.xlabel('月份')
plt.ylabel('取消率')
plt.tight_layout()
plt.show()

# 4. 渠道效果分析
channel_data = df.groupby('market_segment').agg(
    total_bookings=('is_canceled', 'count'),
    cancel_rate=('is_canceled', 'mean'),
    avg_adr=('adr', 'mean')
).sort_values('cancel_rate', ascending=False)

plt.figure(figsize=(10, 6))
sns.scatterplot(
    data=channel_data, 
    x='avg_adr', 
    y='cancel_rate', 
    size='total_bookings', 
    hue=channel_data.index  # 按渠道名称分组上色
)

# 设置标题和坐标轴标签
plt.title('渠道效果分析：房价 vs 取消率', fontsize=14, pad=20)
plt.xlabel('平均房价 (€)', fontsize=12)
plt.ylabel('取消率', fontsize=12)

# 调整图例位置到左上角
plt.legend(
    bbox_to_anchor=(0.1, 0.8),  
    loc='upper left',           
    borderaxespad=1,            
    fontsize=10
)

# 优化布局
plt.tight_layout()
plt.show()

# plt.figure(figsize=(10, 6))
# sns.scatterplot(data=channel_data, x='avg_adr', y='cancel_rate', size='total_bookings', hue=channel_data.index)
# plt.title('渠道效果分析：房价 vs 取消率')
# plt.xlabel('平均房价 (€)')
# plt.ylabel('取消率')
# plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
# plt.show()

# 示例：增加交互式热力图
plt.figure(figsize=(12,8))
sns.heatmap(df.corr(numeric_only=True), annot=True, cmap='coolwarm')
plt.title('特征相关性热力图')
plt.show()