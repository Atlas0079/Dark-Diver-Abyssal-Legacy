import React, { useState } from 'react';
import './TutorialPanel.css';

// 教程内容数据
const tutorialContent = [
	{
		title: "游戏简介",
		content: "NiNard是一款结合棋盘与卡牌元素的策略游戏。在3×3棋盘上放置卡牌，通过巧妙的策略占领对手卡牌并形成特殊组合来获得胜利。",
		image: "tutorial/intro.png"
	},
	{
		title: "游戏设置",
		content: "• 游戏开始时，系统随机决定先手玩家\n• 每位玩家获得5张初始手牌\n• 双方各抽取一张初始卡牌\n• 先手玩家选择一张作为顶部卡牌放在棋盘中央",
		image: "tutorial/setup.png"
	},
	{
		title: "卡牌放置",
		content: "• 玩家轮流在棋盘空位上放置手牌\n• 放置卡牌时，需要选择卡牌的朝向（上、右、下、左）\n• 卡牌一旦放置，就不能再移动位置或改变朝向",
		image: "tutorial/placement.png"
	},
	{
		title: "卡牌占领",
		content: "当你放置卡牌后，如果卡牌朝向指向对手的卡牌，且满足以下条件之一，你可以占领该卡牌：\n• 你的卡牌数值小于对手卡牌的数值\n• 你的卡牌与对手卡牌花色相同\n\n注意：如果两张卡牌朝向相反，则不能占领。",
		image: "tutorial/capture.png"
	},
	{
		title: "连牌加成",
		content: "当你拥有的三张卡牌在同一条直线上时，如果形成以下组合，将获得额外分数：\n• 顺子：三张卡牌数值连续，每张卡牌得分×2\n• 同花：三张卡牌花色相同，每张卡牌得分×2",
		image: "tutorial/combo.png"
	},
	{
		title: "游戏结束与计分",
		content: "• 当9个格子都被填满时，游戏结束\n• 计算每位玩家拥有的卡牌总分值\n• 拥有更高总分的玩家获胜\n• 每张卡牌的基础分值等于其数值",
		image: "tutorial/scoring.png"
	},
	{
		title: "战略提示",
		content: "• 中央和角落位置通常有更高的战略价值\n• 利用花色相同规则占领高价值卡牌\n• 合理选择卡牌朝向，避免被对手占领\n• 始终考虑形成顺子或同花的可能性",
		image: "tutorial/strategy.png"
	}
];

const TutorialPanel = ({ isOpen, onClose }) => {
	const [currentPage, setCurrentPage] = useState(0);
	
	if (!isOpen) return null;
	
	const nextPage = () => {
		if (currentPage < tutorialContent.length - 1) {
			setCurrentPage(currentPage + 1);
		}
	};
	
	const prevPage = () => {
		if (currentPage > 0) {
			setCurrentPage(currentPage - 1);
		}
	};
	
	const goToPage = (pageIndex) => {
		setCurrentPage(pageIndex);
	};
	
	return (
		<div className="tutorial-overlay">
			<div className="tutorial-panel">
				<button className="close-button" onClick={onClose}>×</button>
				
				<div className="tutorial-header">
					<h2>NiNard 游戏教程</h2>
					<div className="page-indicator">
						{tutorialContent.map((_, index) => (
							<div 
								key={index} 
								className={`page-dot ${currentPage === index ? 'active' : ''}`}
								onClick={() => goToPage(index)}
							/>
						))}
					</div>
				</div>
				
				<div className="tutorial-content">
					<h3>{tutorialContent[currentPage].title}</h3>
					<div className="content-container">
						<div className="text-content">
							{tutorialContent[currentPage].content.split('\n').map((line, i) => (
								<p key={i}>{line}</p>
							))}
						</div>
						<div className="image-content">
							<img 
								src={tutorialContent[currentPage].image} 
								alt={`${tutorialContent[currentPage].title} 示例`} 
							/>
						</div>
					</div>
				</div>
				
				<div className="tutorial-navigation">
					<button 
						className="nav-button"
						onClick={prevPage}
						disabled={currentPage === 0}
					>
						上一页
					</button>
					<span className="page-number">{currentPage + 1} / {tutorialContent.length}</span>
					<button 
						className="nav-button"
						onClick={nextPage}
						disabled={currentPage === tutorialContent.length - 1}
					>
						下一页
					</button>
				</div>
			</div>
		</div>
	);
};

export default TutorialPanel; 