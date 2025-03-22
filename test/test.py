import numpy as np
import networkx as nx
import matplotlib.pyplot as plt
from typing import Tuple, List
import random

class DungeonGenerator:
    def __init__(self, grid: np.ndarray, seed: int = None):
        self.grid = grid
        self.height, self.width = grid.shape
        self.graph = nx.Graph()
        self.seed = seed
        self._initialize_graph()
    
    def _initialize_graph(self):
        # 创建节点
        for i in range(self.height):
            for j in range(self.width):
                if self.grid[i,j] == 1:
                    self.graph.add_node((i,j))
        
        # 添加边并设置属性
        directions = [(0,1), (1,0)]  # 右和下
        for i in range(self.height):
            for j in range(self.width):
                if self.grid[i,j] == 1:
                    for di, dj in directions:
                        ni, nj = i + di, j + dj
                        if (ni < self.height and nj < self.width and 
                            self.grid[ni,nj] == 1):
                            self.graph.add_edge((i,j), (ni,nj), 
                                             orientation='H' if di == 0 else 'V')
    
    def _is_bend_node(self, node) -> bool:
        edges = list(self.graph.edges(node))
        if len(edges) != 2:
            return False
        orientations = [self.graph[e[0]][e[1]]['orientation'] for e in edges]
        return orientations[0] != orientations[1]
    
    def _can_remove_edge(self, edge) -> bool:
        # 测试删除边后是否保持强连通
        G = self.graph.copy()
        G.remove_edge(*edge)
        return nx.is_strongly_connected(G.to_directed())
    
    def randomize(self, bend_factor: float, multi_path_factor: float, direction_factor: float):
        """
        bend_factor: 0-1之间，控制曲折度
        multi_path_factor: 0-1之间，控制多通道度
        direction_factor: 0-1之间，控制边变为单向的概率
        """
        # 设置随机种子
        if self.seed is not None:
            random.seed(self.seed)
            
        edges = list(self.graph.edges())
        random.shuffle(edges)
        
        # 处理曲折度
        for edge in edges:
            if random.random() < bend_factor:
                # 尝试删除不会导致曲折的边
                if not self._is_bend_node(edge[0]) and not self._is_bend_node(edge[1]):
                    if self._can_remove_edge(edge):
                        self.graph.remove_edge(*edge)
        
        # 处理多通道度
        nodes = list(self.graph.nodes())
        for node in nodes:
            if random.random() > multi_path_factor:
                edges = list(self.graph.edges(node))
                if len(edges) > 2:
                    random.shuffle(edges)
                    for edge in edges[2:]:
                        if self._can_remove_edge(edge):
                            self.graph.remove_edge(*edge)
        
        # 新增：处理边的方向性
        directed_graph = self.graph.to_directed()
        edges = list(self.graph.edges(data=True))  # 获取边的所有属性
        for edge in edges:
            u, v, data = edge
            if random.random() < direction_factor:
                # 随机选择一个方向删除
                if random.random() < 0.5:
                    directed_graph.remove_edge(u, v)
                else:
                    directed_graph.remove_edge(v, u)
                # 检查是否保持强连通
                if not nx.is_strongly_connected(directed_graph):
                    # 如果不是强连通，恢复边
                    directed_graph.add_edge(u, v, **data)
                    directed_graph.add_edge(v, u, **data)
        
        self.graph = directed_graph
    
    def visualize(self):
        plt.figure(figsize=(10, 10))
        pos = {(i,j): (j, -i) for i,j in self.graph.nodes()}
        
        # 绘制边（修改为支持有向边）
        for edge in self.graph.edges(data=True):
            u, v, data = edge
            # 检查属性是否存在
            orientation = data.get('orientation', 'H')  # 如果没有orientation属性，默认为'H'
            color = 'red' if orientation == 'H' else 'blue'
            nx.draw_networkx_edges(self.graph, pos, edgelist=[(u,v)], 
                                 edge_color=color, width=2,
                                 arrows=True)  # 使用arrows参数替代arrowsize
        
        # 绘制节点
        nx.draw_networkx_nodes(self.graph, pos, node_color='lightgray', 
                             node_size=500)
        
        plt.grid(True)
        plt.axis('equal')
        plt.show()

# 测试代码
if __name__ == "__main__":
    # 创建示例网格
    grid = np.array([
        [0, 0, 0, 0, 0, 0, 0, 0],
        [0, 1, 1, 1, 1, 1, 1, 0],
        [0, 1, 1, 0, 1, 1, 1, 0],
        [0, 1, 1, 1, 1, 1, 0, 0],
        [0, 0, 1, 1, 1, 1, 1, 0],
        [0, 1, 1, 0, 0, 1, 1, 0],
        [0, 1, 1, 1, 1, 1, 1, 0],
        [0, 0, 0, 1, 1, 1, 0, 0]
    ])
    
    # 使用固定种子初始化
    generator = DungeonGenerator(grid, seed=22)  # 42可以换成任何整数
    generator.visualize()  # 显示初始状态
    
    # 随机化处理
    generator.randomize(
        bend_factor=0.3,      # 较低的曲折度
        multi_path_factor=0.5,# 保留大量分支
        direction_factor=0.5  # 少量单向路径
    )
    generator.visualize()
