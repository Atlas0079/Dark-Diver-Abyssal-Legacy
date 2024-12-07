import numpy as np
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap
import random

config = {
    "width": 25,
    "height": 25,
    "ZoneSize": 4,
    "ZoneAmount": 5,
    "MinCluster": 2,
    "MaxCluster": 8,
    "MinClusterDistance": 4,
    "MaxClusterDistance": 15,
    "MaxRoadLength": 8,
    "MaxClusterRoomAmount": 10,
    "MinClusterRoomAmount": 2,
    "growth_bias": 1.0, #越大越倾向聚集
}

def get_neighbor_count(y, x, selected_zones):
    count = 0
    for dy, dx in [(0,1), (0,-1), (1,0), (-1,0), (1,1), (1,-1), (-1,1), (-1,-1)]:
        new_y, new_x = y + dy, x + dx
        if (new_y, new_x) in selected_zones:
            count += 1
    return count

def visualize_zones_and_settlements(config):
    width = config["width"]
    height = config["height"]
    zone_size = config["ZoneSize"]
    
    # 创建基础网格
    grid = np.zeros((height, width))
    
    # 计算区域数量
    zones_x = width // zone_size
    zones_y = height // zone_size
    
    # 创建区域标记数组
    zones = np.zeros((zones_y, zones_x))
    
    # 从中心开始的生长算法
    center_x = zones_x // 2
    center_y = zones_y // 2
    selected_zones = set([(center_y, center_x)])
    
    # 简单的生长算法示例
    for _ in range(config["ZoneAmount"] - 1):
        new_zones = []
        for y, x in selected_zones:
            for dy, dx in [(0,1), (0,-1), (1,0), (-1,0)]:
                new_y, new_x = y + dy, x + dx
                if (0 <= new_y < zones_y and 
                    0 <= new_x < zones_x and 
                    (new_y, new_x) not in selected_zones):
                    # 计算这个位置周围已选择的区块数量
                    neighbor_count = get_neighbor_count(new_y, new_x, selected_zones)
                    # 将位置和权重一起保存，使用growth_bias调整权重
                    weight = (neighbor_count + 1) ** config["growth_bias"]
                    new_zones.append(((new_y, new_x), weight))
        
        if new_zones:
            # 根据权重随机选择
            weights = [weight for _, weight in new_zones]
            positions = [pos for pos, _ in new_zones]
            selected_zones.add(random.choices(positions, weights=weights)[0])
    
    # 标记选中的区域
    for y, x in selected_zones:
        zones[y, x] = 1
        
    # 在选中的区域中随机放置聚落中心
    settlements = []
    max_attempts = 100  # 防止无限循环
    
    for y, x in selected_zones:
        attempts = 0
        while attempts < max_attempts:
            # 在区域内随机选择一个点
            settlement_x = random.randint(x * zone_size, (x + 1) * zone_size - 1)
            settlement_y = random.randint(y * zone_size, (y + 1) * zone_size - 1)
            
            # 检查与现有聚落的距离，使用曼哈顿距离
            valid_position = True
            for existing_y, existing_x in settlements:
                distance = abs(settlement_y - existing_y) + abs(settlement_x - existing_x)
                if distance < config["MinClusterDistance"]:
                    valid_position = False
                    break
            
            if valid_position:
                settlements.append((settlement_y, settlement_x))
                grid[settlement_y, settlement_x] = 2
                break
                
            attempts += 1
            
        if attempts >= max_attempts:
            print(f"警告：在区域({y},{x})无法找到符合距离要求的位置")
    
    # 可视化
    plt.figure(figsize=(10, 10))
    
    # 绘制区域网格
    for i in range(zones_y + 1):
        plt.axhline(y=i * zone_size - 0.5, color='gray', linestyle=':')
    for i in range(zones_x + 1):
        plt.axvline(x=i * zone_size - 0.5, color='gray', linestyle=':')
    
    # 创建自定义颜色映射
    colors = ['lightgray', 'lightblue', 'red']
    cmap = ListedColormap(colors)
    
    # 绘制网格和聚落
    plt.imshow(grid, cmap=cmap)
    
    # 标记选中的区域
    for y, x in selected_zones:
        plt.fill([x * zone_size - 0.5, (x + 1) * zone_size - 0.5, 
                 (x + 1) * zone_size - 0.5, x * zone_size - 0.5],
                [y * zone_size - 0.5, y * zone_size - 0.5, 
                 (y + 1) * zone_size - 0.5, (y + 1) * zone_size - 0.5],
                alpha=0.2, color='blue')
    
    plt.grid(True)
    plt.title('Dungeon Zones and Settlements')
    plt.show()
    
    return grid, settlements

def visualize_dungeon_growth(config, grid, settlements):
    plt.ion()  # 打开交互模式
    fig = plt.figure(figsize=(10, 10))
    
    colors = ['lightgray', 'lightblue', 'red', 'green']  # 添加绿色表示房间
    cmap = ListedColormap(colors)
    
    # 为每个聚落生成房间
    for settlement in settlements:
        rooms = set([settlement])  # 初始只有聚落中心
        room_amount = random.randint(
            config["MinClusterRoomAmount"], 
            config["MaxClusterRoomAmount"]
        )
        
        # 生长过程
        for _ in range(room_amount):
            candidates = []
            # 检查所有现有房间的邻接位置
            for room_y, room_x in rooms:
                for dy, dx in [(0,1), (0,-1), (1,0), (-1,0)]:
                    new_y, new_x = room_y + dy, room_x + dx
                    if (0 <= new_y < config["height"] and 
                        0 <= new_x < config["width"] and 
                        grid[new_y, new_x] == 0 and  # 确保位置为空
                        (new_y, new_x) not in rooms):
                        # 计算这个位置周围已有的房间数量
                        neighbor_count = sum(1 for dy2, dx2 in [(0,1), (0,-1), (1,0), (-1,0)]
                                          if (new_y + dy2, new_x + dx2) in rooms)
                        candidates.append(((new_y, new_x), neighbor_count + 1))
            
            if candidates:
                # 根据权重选择新房间
                weights = [weight for _, weight in candidates]
                positions = [pos for pos, _ in candidates]
                new_room = random.choices(positions, weights=weights)[0]
                rooms.add(new_room)
                grid[new_room[0], new_room[1]] = 3  # 3表示普通房间
        
        # 在每个聚落完成后更新显示
        plt.clf()
        plt.subplot(1, 3, 2)
        plt.imshow(grid, cmap=cmap)
        plt.grid(True)
        plt.title(f'Dungeon Growth - Settlement {settlements.index(settlement) + 1}')
        plt.pause(0.5)  # 暂停0.5秒
    
    plt.ioff()  # 关闭交互模式
    plt.show()
    return grid

def find_path(start, end, grid, config):
    """使用A*算法寻找两点间的最短路径"""
    def manhattan_distance(p1, p2):
        return abs(p1[0] - p2[0]) + abs(p1[1] - p2[1])
    
    def get_neighbors(pos):
        y, x = pos
        for dy, dx in [(0,1), (0,-1), (1,0), (-1,0)]:
            new_y, new_x = y + dy, x + dx
            if (0 <= new_y < config["height"] and 
                0 <= new_x < config["width"]):
                yield (new_y, new_x)
    
    from heapq import heappush, heappop
    
    frontier = [(0, start)]
    came_from = {start: None}
    cost_so_far = {start: 0}
    
    while frontier:
        current = heappop(frontier)[1]
        
        if current == end:
            break
            
        for next_pos in get_neighbors(current):
            new_cost = cost_so_far[current] + 1
            
            if (next_pos not in cost_so_far or new_cost < cost_so_far[next_pos]):
                cost_so_far[next_pos] = new_cost
                priority = new_cost + manhattan_distance(next_pos, end)
                heappush(frontier, (priority, next_pos))
                came_from[next_pos] = current
    
    # 重建路径
    if end not in came_from:
        return None
        
    path = []
    current = end
    while current is not None:
        path.append(current)
        current = came_from[current]
    path.reverse()
    return path

def connect_settlements(config, grid, settlements):
    plt.ion()
    
    # 创建新的颜色映射，添加路径颜色
    colors = ['lightgray', 'lightblue', 'red', 'green', 'yellow']  # 黄色表示路径
    cmap = ListedColormap(colors)
    
    # 获取每个聚落所在的区块
    settlement_zones = {}
    zone_size = config["ZoneSize"]
    for settlement in settlements:
        y, x = settlement
        zone_y, zone_x = y // zone_size, x // zone_size
        settlement_zones[settlement] = (zone_y, zone_x)
    
    def is_connected(start, target, grid):
        """检查两个点是否已经通过房间连接"""
        visited = set()
        queue = [start]
        visited.add(start)
        
        while queue:
            current = queue.pop(0)
            if current == target:
                return True
                
            for dy, dx in [(0,1), (0,-1), (1,0), (-1,0)]:
                new_y, new_x = current[0] + dy, current[1] + dx
                new_pos = (new_y, new_x)
                
                if (0 <= new_y < config["height"] and 
                    0 <= new_x < config["width"] and 
                    new_pos not in visited and 
                    grid[new_y, new_x] in [2, 3]):  # 2是聚落中心，3是房间
                    queue.append(new_pos)
                    visited.add(new_pos)
        
        return False

    # 在检查每对聚落时，添加连通性检查
    for i, settlement1 in enumerate(settlements):
        for settlement2 in settlements[i+1:]:
            zone1 = settlement_zones[settlement1]
            zone2 = settlement_zones[settlement2]
            
            # 检查区块是否相邻且尚未连通
            if ((abs(zone1[0] - zone2[0]) + abs(zone1[1] - zone2[1])) == 1 and 
                not is_connected(settlement1, settlement2, grid)):
                
                # 寻找路径
                path = find_path(settlement1, settlement2, grid, config)
                if path:
                    # 创建路径
                    for pos in path[1:-1]:
                        if grid[pos[0], pos[1]] == 0:
                            grid[pos[0], pos[1]] = 4
                    
                    # 更新显示
                    plt.clf()
                    plt.imshow(grid, cmap=cmap)
                    plt.grid(True)
                    plt.title('Connecting Settlements')
                    plt.pause(0.5)
    
    plt.ioff()
    plt.show()
    return grid

# 测试可视化
grid, settlements = visualize_zones_and_settlements(config)
grid = visualize_dungeon_growth(config, grid, settlements)
grid = connect_settlements(config, grid, settlements)

